defmodule ClientMetricCollector do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    :client_metrics = :ets.new(:client_metrics, [:named_table, :public])

    # Start routine
    crawl_client()
    {:ok, state}
  end

  def handle_info(:crawl_client, state) do
    task_crawl_client()

    crawl_client()
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp task_crawl_client() do
    clients = :dets.select(:clients, [{:"$1", [], [:"$1"]}])

    clients |>
    Enum.each(fn client -> Task.Supervisor.start_child(
      ClientMetricCollector.Crawler,
      fn -> crawl(client) end
    ) end)
  end

  defp crawl(client) do
    # client = {name, %{name: name, host: host, fingerprint: fingerprint}}
    {name, info} = client
    %{"name" => ^name, "host" => host, "fingerprint" => fingerprint} = info

    command = ["metric", "cpu", "memory", "disk", "network", "uptime", "loadavg", "userlist"]
              |> pack()

    # Caution: `host` must be charlist
    general_config = Application.get_env(:server, :general)
    network_config = Application.get_env(:server, :network)
    port = network_config |> Keyword.fetch!(:client_port)
    timeout = network_config |> Keyword.fetch!(:timeout)
    cert_path = general_config |> Keyword.fetch!(:cert_path)
    key_path = general_config |> Keyword.fetch!(:key_path)
    cacert_path = Application.app_dir(:server, "priv") |> Path.join("cacert.pem")
    opts = [
      :binary,
      active: false,
      verify_fun: {&:ssl_verify_fingerprint.verify_fun/3,
        [{:check_fingerprint, {:sha256, fingerprint}}]},
      verify: :verify_peer,
      certfile: cert_path,
      keyfile: key_path,
      cacertfile: cacert_path,
    ]
    metric_data = case :ssl.connect(host, port, opts, timeout) do
      {:ok, socket} ->
        :ssl.send(socket, command <> "\n")
        case :ssl.recv(socket, 0, timeout) do
          {:ok, data} ->
            :ssl.close(socket)
            data |> unpack()

          {:error, _reason} -> :not_available
        end

      {:error, {:tls_alert, _reason}} -> :invalid_connection

      {:error, _reason} -> :not_available
    end
    :ets.insert(:client_metrics, {name, metric_data})
  end

  defp pack(data) do
    data
    |> Msgpax.pack!()
    |> IO.iodata_to_binary()
    |> Base.encode64
  end

  defp unpack(data) do
    data
    |> String.trim()
    |> Base.decode64!()
    |> Msgpax.unpack!()
  end

  defp crawl_client() do
    interval = Application.get_env(:server, :general) |> Keyword.fetch!(:crawl_interval)
    Process.send_after(self(), :crawl_client, interval)
  end

end
