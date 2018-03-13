defmodule Server do
  use Application
  require Logger
  require ServerSupervisor

  def start(_type, _args) do
    :ssl.start()
    init_secret_key()
    init_database()
    start_cowboy()
    ServerSupervisor.start_link([])
  end

  def stop(_state) do
    :dets.close(:clients)
    :dets.close(:script_results)
    :ssl.stop()
    :ok
  end

  defp init_database() do
    client_db_filename = Application.get_env(:server, :general) |> Keyword.fetch!(:client_db_filename)
    opts = [file: client_db_filename]
    :dets.open_file(:clients, opts)

    script_db_filename = Application.get_env(:server, :general) |> Keyword.fetch!(:script_db_filename)
    opts = [file: script_db_filename]
    :dets.open_file(:script_results, opts)
  end

  defp start_cowboy() do
    Logger.info("Starting cowboy")

    router =
      :cowboy_router.compile([
        {:_,
         [
           {"/api/metric/[:machine_name]", API.Metric, []},
           {"/api/machines/[:machine_name]", API.Machine, []},
           {"/api/machines/:machine_name/tags", API.Tag, []}
         ]}
      ])

    api_port =
      Application.get_env(:server, :network)
      |> Keyword.fetch!(:api_port)

    {:ok, _} = :cowboy.start_clear(:api_server, [port: api_port], %{env: %{dispatch: router}})
  end

  defp init_secret_key() do
    priv_path = Application.app_dir(:server, "priv")
    secret_key_path = Path.join(priv_path, "secret_key")

    unless File.exists?(secret_key_path) do
      Logger.info("Generating new secret key")
      charset = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
      random_secret = charset |> Enum.take_random(64) |> to_string()

      File.mkdir_p!(priv_path)
      File.write(secret_key_path, random_secret)
    end

    :ets.new(:secret, [:named_table])
    :ets.insert(:secret, {:secret, File.read!(secret_key_path)})
  end
end
