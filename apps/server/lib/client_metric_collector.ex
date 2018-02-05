defmodule ClientMetricCollector do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # TODO: get file name from config
    :ok = load_all_clients_from_file(:client_db)

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
    # TODO: crawl!

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
    # client = {:name, %{name: name, host: host}}

  end

  defp crawl_client() do
    # TODO: get interval from config
    Process.send_after(self(), :crawl_client, 3000)
  end

end
