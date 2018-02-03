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
    :disk
  end

  def fetch_network_usage do
    :network
  end
end
