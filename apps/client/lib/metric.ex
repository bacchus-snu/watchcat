defmodule Metric do
  def fetch_cpu_usage do
    :cpu
  end

  def fetch_memory_usage do
    {output, status} = System.cmd("cat", ["/proc/meminfo"])

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

    case {output, status} do
      {output, 0} ->
        output
        |> String.trim
        |> String.split("\n")
        |> List.foldl(%{}, parse_and_add)
      {_, _} ->
        %{}
    end
  end

  def fetch_disk_usage do
    percentage_to_number = fn(percentage) ->
      percentage
      |> String.slice(0, String.length(percentage)-1)
      |> String.to_integer
    end

    {output, status} = System.cmd("df", ["-P", "-k", "/"])

    case {output, status} do
      {output, 0} ->
        [headers | disk_infos] =
          output
          |> String.trim
          |> String.split("\n")
          |> Enum.map(&String.split/1)

        disk_infos
        # "on" is truncated in header "Mounted on", so key is "Mounted"
        |> Enum.map(fn(x) -> Enum.zip(headers, x) |> Map.new end)
        |> Enum.map(
          # values are negative when info not exist
          fn(disk_info) ->
            disk_info
            |> Map.update("1024-blocks", -1, &String.to_integer/1)
            |> Map.update("Used", -1, &String.to_integer/1)
            |> Map.update("Available", -1, &String.to_integer/1)
            |> Map.update("Capacity", -1, percentage_to_number)
          end
        )

      {_, _} ->
        []
    end
  end

  def fetch_network_usage do
    :network
  end
end