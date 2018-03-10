defmodule Collector do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # Setup ETS table
    :ets.new(:metric, [:named_table])

    Enum.each([:cpu, :memory, :disk, :network, :uptime, :loadavg, :userlist], fn key ->
      :ets.insert(:metric, {key, {:error, "initially not available"}})
    end)

    routine()
    {:ok, state}
  end

  def handle_info(:collect_metric, state) do
    # TODO: make below ASYNC
    routine()
    collect_metric()
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp collect_metric() do
    # metric has form {:ok, metric} or {:error, reason}
    metrics_raw = [
      {:cpu_raw, Metric.fetch_cpu_metric()},
      {:memory_raw, Metric.fetch_memory_metric()},
      {:disk_raw, Metric.fetch_disk_metric()},
      {:network_raw, Metric.fetch_network_metric()}
    ]

    [cpu, memory, disk, network] = metrics_raw

    metrics = [
      {:cpu, calculate_cpu_usage(cpu)},
      {:memory, calculate_memory_usage(memory)},
      {:disk, calculate_disk_usage(disk)},
      {:network, calculate_network_usage(network)},
      # don't need to calculate
      {:uptime, Metric.fetch_uptime()},
      {:loadavg, Metric.fetch_loadavg()},
      {:userlist, Metric.fetch_userlist()},
      # get timestamp also
      {:timestamp, timestamp()}
    ]

    # Update new metric information
    :ets.insert(:metric, metrics)

    :ets.insert(:metric, metrics_raw)
  end

  defp calculate_cpu_usage({:cpu_raw, raw}) do
    case raw do
      {:ok, curr} ->
        {:cpu_raw, {:ok, prev}} = :ets.lookup(:metric, :cpu_raw) |> List.first()

        cpu_info =
          for {prev_core, curr_core} <- Enum.zip(prev, curr),
              name = prev_core["name"],
              idle = curr_core["idle"] - prev_core["idle"],
              total = curr_core["total"] - prev_core["total"],
              usage_percent = (total - idle) / total * 100 do
            %{"name" => name, "usage" => usage_percent}
          end

        {:ok, cpu_info}

      {:error, _} = e ->
        e
    end
  rescue
    MatchError ->
      {:error, "previous metric not available"}
  end

  defp calculate_memory_usage({:memory_raw, raw}) do
    case raw do
      {:ok, m} ->
        total = m["MemTotal"]
        used = total - m["MemFree"]
        buffer = m["Buffers"]
        cached = m["Cached"] + m["SReclaimable"] - m["Shmem"]
        swap_total = m["SwapTotal"]
        swap_free = m["SwapFree"]
        available = total - (used - buffer - cached)

        memory_info = %{
          "total" => total,
          "used" => used,
          "buffer" => buffer,
          "cached" => cached,
          "swap_total" => swap_total,
          "swap_free" => swap_free,
          "available" => available
        }

        {:ok, memory_info}

      {:error, _} = e ->
        e
    end
  end

  defp calculate_disk_usage({:disk_raw, raw}) do
    case raw do
      {:ok, disks} ->
        disk_info =
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
              "used_percent" => used / total * 100
            }
          end

        {:ok, disk_info}

      {:error, _} = e ->
        e
    end
  end

  defp calculate_network_usage({:network_raw, raw}) do
    case raw do
      {:ok, curr} ->
        {:network_raw, {:ok, prev}} = :ets.lookup(:metric, :network_raw) |> List.first()

        network_info =
          for {pn, cn} <- Enum.zip(prev, curr),
              name = pn["name"],
              rx = cn["rx"] - pn["rx"],
              tx = cn["tx"] - pn["tx"],
              # TODO: more precise time interval
              rx_speed = rx / 1024,
              tx_speed = tx / 1024 do
            %{"name" => name, "tx_speed" => tx_speed, "rx_speed" => rx_speed}
          end

        {:ok, network_info}

      {:error, _} = e ->
        e
    end
  rescue
    MatchError ->
      {:error, "previous metric not available"}
  end

  defp routine() do
    interval = Application.get_env(:client, :general) |> Keyword.fetch!(:collect_interval)
    Process.send_after(self(), :collect_metric, interval)
  end

  defp timestamp() do
    DateTime.utc_now() |> DateTime.to_unix()
  end
end
