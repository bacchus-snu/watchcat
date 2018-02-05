defmodule ClientMetricCollector do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # TODO: get file name from config
    :ok = load_all_clients_from_file(:client_db)
    :ets.new(:client_metrics, [:named_table])

    # Start routine
    crawl_client()
    {:ok, state}
  end

  defp load_all_clients_from_file(file) do
    {:ok, table} = :dets.open_file(file, [type: :set])
    :ets.new(:clients, [:named_table])
    :ets.insert(:clients, :dets.select(table, :ets.fun2ms(fn x -> x end)))
    :dets.close(table)
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
    clients = :ets.select(:clients, :ets.fun2ms(fn x -> x end))

    clients |>
    Enum.each(fn client -> Task.Supervisor.start_child(
      ClientMetricCollector.Crawler,
      fn -> crawl(client) end
    ) end)
  end

  defp crawl(client) do
    # client = {name, %{name: name, host: host}}
    {name, info} = client
    %{name: ^name, host: host} = info

    command = ["metric", ["cpu", "memory", "disk", "network", "uptime"]] |> pack()

    # Caution: `host` must be charlist
    # TODO: get port and timeout from config
    metric_data = case :gen_tcp.connect(host, 10101, {:binary, active: false}, 1000) do
      {:ok, socket} ->
        :gen_tcp.send(socket, command <> "\n")
        case :gen_tcp.recv(socket, 0, 1000) do
          {:ok, data} ->
            data |> unpack()

          {:error, _reason} -> :not_available
        end

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
    # TODO: get interval from config
    Process.send_after(self(), :crawl_client, 3000)
  end

end
