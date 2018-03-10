defmodule Metric do
  def fetch_cpu_metric() do
    import String

    {output, 0} = System.cmd("cat", ["/proc/stat"])

    cpus =
      for cpu <- output |> trim |> split("\n"),
          Regex.match?(~r/^cpu(\d+)?\s/, cpu),
          [name | values] = cpu |> trim |> split,
          values = values |> Enum.map(&to_integer/1),
          total = values |> Enum.sum(),
          idle = values |> Enum.at(3) do
        %{"name" => name, "total" => total, "idle" => idle}
      end

    {:ok, cpus}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  @doc """
  Fetch the memory metric.
  """
  def fetch_memory_metric() do
    {output, 0} = System.cmd("cat", ["/proc/meminfo"])

    regex = ~r/(?<key>\S+):\s*(?<value>\d+)/

    meminfos =
      for line <- output |> String.trim() |> String.split("\n"),
          %{"key" => key, "value" => val} = Regex.named_captures(regex, line),
          val = String.to_integer(val),
          into: %{},
          do: {key, val}

    {:ok, meminfos}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  @doc """
  Fetch the disk metric.
  """
  def fetch_disk_metric() do
    {output, 0} = System.cmd("df", ["-l", "-k", "-P", "-T", "-x", "tmpfs", "-x", "devtmpfs"])

    percent_to_number = fn percent ->
      percent
      |> String.replace_suffix("%", "")
      |> String.to_integer()
    end

    update_info = fn disk_info ->
      disk_info
      |> Map.update("1024-blocks", -1, &String.to_integer/1)
      |> Map.update("Used", -1, &String.to_integer/1)
      |> Map.update("Available", -1, &String.to_integer/1)
      |> Map.update("Capacity", -1, percent_to_number)
    end

    [headers | disks] =
      output
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&String.split/1)

    disk_infos =
      for disk <- disks do
        Enum.zip(headers, disk)
        |> Map.new()
        |> update_info.()
      end

    {:ok, disk_infos}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  @doc """
  Fetch the network metric for each network interface.
  """
  def fetch_network_metric() do
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
  Fetch the system load averages for the past 1, 5, and 15 minutes.
  """
  def fetch_loadavg() do
    {output, 0} = System.cmd("cat", ["/proc/loadavg"])
    [load1, load5, load15 | _] = output |> String.trim() |> String.split()
    load = [load1, load5, load15] |> Enum.map(&String.to_float/1)

    {:ok, load}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  @doc """
  Fetch list of user who currently logged in.
  """
  def fetch_userlist() do
    {output, 0} = System.cmd("who", ["-q"])

    userlist =
      output
      |> String.split("\n")
      |> List.first()
      |> String.split()

    {:ok, userlist}
  rescue
    _ ->
      {:error, "system command fail"}
  end

  @doc """
  Fetch uptime in second(float).
  """
  def fetch_uptime() do
    {output, 0} = System.cmd("cat", ["/proc/uptime"])
    [total, _idle] = output |> String.trim() |> String.split()

    {:ok, total |> String.to_float()}
  rescue
    _ ->
      {:error, "system command fail"}
  end
end
