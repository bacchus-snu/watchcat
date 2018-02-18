defmodule Metric do
  def fetch_cpu_usage do
    import String

    {output, 0} = System.cmd("cat", ["/proc/stat"])

    cpus =
      output
      |> trim
      |> split("\n")
      |> Enum.filter(fn line -> Regex.match?(~r/^cpu(\d+)?\s/, line) end)

    cpus =
      for cpu <- cpus,
          [name | values] = cpu |> trim |> split,
          values = values |> Enum.map(&to_integer/1),
          total = values |> Enum.sum,
          idle = values |> Enum.at(3) do
        %{"name" => name, "total" => total, "idle" => idle}
      end

    {:ok, cpus}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  def fetch_memory_usage do
    {output, 0} = System.cmd("cat", ["/proc/meminfo"])

    parse_and_add = fn (line, map) ->
      # match "key: value"
      match = Regex.named_captures(~r/(?<key>\S+):\s*(?<value>\d+)/, line)
      case match do
        %{"key" => key, "value" => value} ->
          Map.put(map, key, String.to_integer(value))
        nil ->
          map
      end
    end

    map =
      output
      |> String.trim
      |> String.split("\n")
      |> List.foldl(%{}, parse_and_add)

    {:ok, map}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  def fetch_disk_usage do
    percentage_to_number = fn(percentage) ->
      percentage
      |> String.slice(0, String.length(percentage)-1)
      |> String.to_integer
    end

    {output, 0} = System.cmd("df", ["-l", "-k", "-P", "-T", "-x", "tmpfs", "-x", "devtmpfs"])

    [headers | disk_infos] =
      output
      |> String.trim
      |> String.split("\n")
      |> Enum.map(&String.split/1)

    disk_infos =
      disk_infos
      # "on" is truncated in header "Mounted on", so key is "Mounted"
      |> Enum.map(fn(x) -> Enum.zip(headers, x) |> Map.new end)
      |> Enum.map(
        # values are negative when info not exist
        fn disk_info ->
          disk_info
          |> Map.update("1024-blocks", -1, &String.to_integer/1)
          |> Map.update("Used", -1, &String.to_integer/1)
          |> Map.update("Available", -1, &String.to_integer/1)
          |> Map.update("Capacity", -1, percentage_to_number)
        end
      )

    {:ok, disk_infos}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  def fetch_network_usage do
    import String
    {:ok, interfaces} = File.ls("/sys/class/net/")

    interfaces =
      for iface <- interfaces,
          {:ok, rx} = File.read("/sys/class/net/#{iface}/statistics/rx_bytes"),
          {:ok, tx} = File.read("/sys/class/net/#{iface}/statistics/tx_bytes") do
        %{"name" => iface, "rx" => rx |> trim |> to_integer, "tx" => tx |> trim |> to_integer}
      end
    {:ok, interfaces}
  end

  @doc """
  fetch the system load averages for the past 1, 5, and 15 minutes.
  """
  def fetch_loadavg do
    {output, 0} = System.cmd("cat", ["/proc/loadavg"])
    [load1, load5, load15 | _] = output |> String.trim |> String.split
    load = [load1, load5, load15] |> Enum.map(&String.to_float/1)

    {:ok, load}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  @doc """
  fetch list of user who currently logged in
  """
  def fetch_userlist do
    {output, 0} = System.cmd("who", ["-q"])

    userlist =
      output
      |> String.trim
      |> String.split("\n")
      |> List.first()
      |> String.split()

    {:ok, userlist}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  @doc """
  fetch uptime in second (float)
  """
  def fetch_uptime do
    {output, 0} = System.cmd("cat", ["/proc/uptime"])
    [total, _idle] = output |> String.trim |> String.split

    {:ok, total |> String.to_float}
  rescue
    _ ->
      {:error, "system command fail"}
  end
end
