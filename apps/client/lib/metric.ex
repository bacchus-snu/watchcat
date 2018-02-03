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

    fold = fn (res, map) ->
      case res do
        {:ok, %{key: key, value: value}} ->
          %{map | key => value}
          Map.put(map, key, value)
        {:error, _} ->
          map
      end
    end

    case {output, status} do
      {output, 0} ->
        output
        |> String.trim |> String.split("\n")
        |> Enum.map(parse_line) |> List.foldl(%{}, fold)
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
