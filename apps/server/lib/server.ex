defmodule Server do
  use Application
  require Logger
  require ServerSupervisor

  def start(_type, _args) do
    init_secret_key()
    start_cowboy()
    ServerSupervisor.start_link([])
  end

  defp start_cowboy() do
    Logger.info("Starting cowboy")
    router = :cowboy_router.compile([
      {:"_", [
        {"/api/metric/[:machine]", HTTPHandler.MetricReq, []},
        {"/api/machines", HTTPHandler.MachineReq, []},
      ]}
    ])
    {:ok, _} = :cowboy.start_clear(
      :api_server,
      [port: 10102],
      %{env: %{dispatch: router}}
    )
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
