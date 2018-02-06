defmodule HTTPHandler.MetricReq do
  import Ex2ms
  def init(req0 = %{method: "GET"}, state) do
    machine = :cowboy_req.binding(:machine, req0)

    {code, contents} =
      case machine do
        :undefined ->
          machines = :ets.select(
            :client_metrics,
            fun do
              {x, y} ->
                %{"name" => x, "metric" => y}
            end
          )
          {200, machines}

        machine_key ->
          machines = :ets.select(
            :client_metrics,
            fun do
              {key, metric} when key == ^machine_key ->
                %{"name" => key, "metric" => metric}
            end
          )
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
    {machines = :ets.select(:clients, fun do {x, y} -> y end)

    contents =
      machines |> Poison.encode!

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
