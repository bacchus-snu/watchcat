defmodule PeriodicCollect do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # Setup ETS table
    :ets.new(:metric, [:named_table])

    metric_collection()
    {:ok, state}
  end

  def handle_info(:collect_metric, state) do
    # do something...
    # TODO: make below ASYNC
    task_collect_metric()
    metric_collection()
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp task_collect_metric() do
    metrics = [
      {:cpu_raw, Metric.fetch_cpu_usage},
      {:memory_raw, Metric.fetch_memory_usage},
      {:disk_raw, Metric.fetch_disk_usage},
      {:network_raw, Metric.fetch_network_usage},
    ]

    [cpu, memory, disk, network] = metrics

    # Update new metric information
    :ets.insert(:metric, {:cpu, calculate_cpu_usage(cpu)})
    :ets.insert(:metric, {:memory, calculate_memory_usage(memory)})
    :ets.insert(:metric, {:disk, calculate_disk_usage(disk)})
    :ets.insert(:metric, {:network, calculate_network_usage(network)})

    :ets.insert(:metric, metrics)
  end

  defp calculate_cpu_usage({:cpu_raw, curr}) do
    case :ets.lookup(:metric, :cpu_raw) |> List.first do
      nil ->
        :not_available
      {:cpu_raw, prev} ->
        for {prev_core, curr_core} <- Enum.zip(prev, curr),
          name = prev_core["name"],
          idle = curr_core["idle"] - prev_core["idle"],
          total = curr_core["total"] - prev_core["total"],
          usage_percent = ((total - idle) / total) * 100 do
            %{"name" => name, "usage" => usage_percent}
        end
    end
  end

  defp calculate_memory_usage({:memory_raw, m}) do
    total = m["MemTotal"]
    used = total - m["MemFree"]
    buffer = m["Buffers"]
    cached = m["Cached"] + m["SReclaimable"] - m["Shmem"]
    swap_total = m["SwapTotal"]
    swap_free = m["SwapFree"]
    available = total - (used - buffer - cached)
    %{
      "total" => total,
      "used" => used,
      "buffer" => buffer,
      "cached" => cached,
      "swap_total" => swap_total,
      "swap_free" => swap_free,
      "available" => available,
    }
  end

  defp calculate_disk_usage({:disk_raw, metric}) do
    for part <- metric,
      total = part["1024-blocks"],
      used = part["Used"],
      filesystem = part["Filesystem"],
      mountpoint = part["Mounted"] do
        %{
          "total" => total,
          "used" => used,
          "filesystem" => filesystem,
          "mountpoint" => mountpoint,
          "used_percent" => (used / total) * 100,
        }
      end
  end

  defp calculate_network_usage({:network_raw, curr}) do
    case :ets.lookup(:metric, :network_raw) |> List.first do
      nil ->
        :not_available
      {:network_raw, prev} ->
        for {pn, cn} <- Enum.zip(prev, curr),
          name = pn["name"],
          rx = cn["rx"] - pn["rx"], tx = cn["tx"] - pn["tx"],
          # TODO: more precise time interval
          rx_speed = rx / 1024,
          tx_speed = tx / 1024 do
            %{"name" => name, "tx_speed" => tx_speed, "rx_speed" => rx_speed}
        end
    end
  end

  defp metric_collection() do
    # Periodic task of 1000ms
    Process.send_after(self(), :collect_metric, 1000)
  end

end
