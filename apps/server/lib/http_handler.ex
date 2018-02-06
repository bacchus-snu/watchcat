defmodule HTTPHandler.MetricReq do
  import Ex2ms
  def init(req0 = %{method: "GET"}, state) do
    machine = :cowboy_req.binding(:machine, req0)

    {code, contents} =
      case machine do
        :undefined ->
          machines_raw = :ets.select(
            :client_metrics,
            fun do x -> x end
          )
          machines = machines_raw
                     |> Enum.map(fn {x, y} -> %{"name" => x, "metric" => y} end)
          {200, machines}

        machine_key ->
          machines_raw = :ets.select(
            :client_metrics,
            fun do {key, metric} when key == ^machine_key -> {key, metric} end
          )
          machines = machines_raw
                     |> Enum.map(fn {x, y} -> %{"name" => x, "metric" => y} end)
          case machines do
            [] ->
              {404, ""}
            [machine | _] ->
              {200, machine}
          end
      end

    contents =
      case code do
        200 ->
          contents |> Poison.encode!
        _ ->
          contents
      end

    req = :cowboy_req.reply(
      code,
      %{"content-type" => "application/json"},
      contents,
      req0
      )
      {:ok, req, state}
  end

  # fall back other method
  def init(req0, state) do
    req = :cowboy_req.reply(
      405,
      %{"content-type" => "text/plain"},
      "",
      req0
      )
    {:ok, req, state}
  end
end

defmodule HTTPHandler.MachineReq do
  import Ex2ms
  def init(req0 = %{method: "GET"}, state) do
    machines = :ets.select(:clients, fun do {x, y} -> y end)
    update = fn x -> Map.update!(x, :host, &to_string/1) end
    contents =
      machines
      |> Enum.map(update)
      |> Poison.encode!

    req = :cowboy_req.reply(
      200,
      %{"content-type" => "text/plain"},
      contents,
      req0
      )
    {:ok, req, state}
  end

  # fall back other method
  def init(req0, state) do
    req = :cowboy_req.reply(
      405,
      %{"content-type" => "text/plain"},
      "",
      req0
      )
    {:ok, req, state}
  end
end
