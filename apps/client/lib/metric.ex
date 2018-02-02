defmodule Metric do
  def fetch_cpu_usage do
    :cpu
  end

  def fetch_memory_usage do
    {output, status} = System.cmd("cat", ["/proc/meminfo"])

    parse_line = fn line ->
      try do
        [key | tail] = line |> String.split(":")
        value = tail |> List.first |> String.trim |> String.split |> List.first
        {:ok, %{key: key, value: String.to_integer(value)}}
      rescue
        e in MatchError ->
          {:error, e}
      end
    end

    case {output, status} do
      {output, 0} ->
        lines = output |> String.trim |> String.split("\n")
        fold = fn (res, map) ->
          case res do
            {:ok, %{key: key, value: value}} ->
              Map.put(map, key, value)
            {:error, _} ->
              map
          end
        end
        meminfo_map = lines |> Enum.map(parse_line) |> List.foldl(%{}, fold)
        meminfo_map

      _ ->
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
