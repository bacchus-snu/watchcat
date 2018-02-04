defmodule Collector do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # Setup ETS table
    :ets.new(:metric, [:named_table])

    Enum.each(
      [:cpu, :memory, :disk, :network, :uptime],
      fn key ->
        :ets.insert(:metric, {key, :not_available})
      end
    )

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
      {:uptime_raw, Metric.fetch_uptime},
    ]

    metrics =
      Enum.map(metrics, fn {key, res} ->
        case res do
          {:ok, raw} ->
            {key, raw}
          {:error, _msg} ->
            {key, :not_available}
        end
      end
      )

    [cpu, memory, disk, network, uptime] = metrics

    # Update new metric information
    :ets.insert(:metric, {:cpu, calculate_cpu_usage(cpu)})
    :ets.insert(:metric, {:memory, calculate_memory_usage(memory)})
    :ets.insert(:metric, {:disk, calculate_disk_usage(disk)})
    :ets.insert(:metric, {:network, calculate_network_usage(network)})
    :ets.insert(:metric, {:uptime, calculate_uptime(uptime)})

    :ets.insert(:metric, metrics)
  end

  defp calculate_cpu_usage({:cpu_raw, raw}) do
    case raw do
      :not_available ->
        :not_available

      curr ->
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
  end

  defp calculate_memory_usage({:memory_raw, raw}) do
    case raw do
      :not_available ->
        :not_available

      m ->
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
  end

  defp calculate_disk_usage({:disk_raw, raw}) do
    case raw do
      :not_available ->
        :not_available

      disks ->
        for part <- disks,
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
  end

  defp calculate_network_usage({:network_raw, raw}) do
    case raw do
      :not_available ->
        :not_available

      curr ->
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
  end

  defp calculate_uptime({:uptime_raw, raw}) do
    case raw do
      :not_available ->
        :not_available
      m ->
        %{
          "load" => [m["load1"], m["load5"], m["load15"]],
          "uptime" => [m["days"], m["hour"], m["minute"]],
          "time" => m["time"],
          "users" => m["users"],
        }
    end
  end

  defp metric_collection() do
    # Periodic task of 1000ms
    Process.send_after(self(), :collect_metric, 1000)
  end

end
