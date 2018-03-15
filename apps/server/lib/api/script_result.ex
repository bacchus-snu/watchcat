defmodule API.ScriptResult do
  def init(req0 = %{method: "GET"}, state) do
    permission = req0 |> API.get_permission()

    if permission != "admin" do
      req = :cowboy_req.reply(403, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
    else
      id = :cowboy_req.binding(:id, req0)

      case :dets.lookup(:script_results, id) do
        [] ->
          req =
            :cowboy_req.reply(
              404,
              %{"content-type" => "application/json"},
              %{status: "not found"} |> Poison.encode!(),
              req0
            )

          {:ok, req, state}

        [{^id, %{name: name, data: result, timestamp: timestamp}}] ->
          case result do
            :not_available ->
              req =
                :cowboy_req.reply(
                  202,
                  %{"content-type" => "application/json"},
                  %{name: name, status: "not available", timestamp: timestamp}
                  |> Poison.encode!(),
                  req0
                )

              {:ok, req, state}

            script_result when is_map(script_result) ->
              req =
                :cowboy_req.reply(
                  200,
                  %{"content-type" => "application/json"},
                  %{name: name, status: "ok", data: script_result, timestamp: timestamp}
                  |> Poison.encode!(),
                  req0
                )

              {:ok, req, state}

            _ ->
              req =
                :cowboy_req.reply(
                  500,
                  %{"content-type" => "text/plain"},
                  "",
                  req0
                )

              {:ok, req, state}
          end
      end
    end
  end

  def init(req0, state) do
    req =
      :cowboy_req.reply(
        405,
        %{"content-type" => "text/plain"},
        "",
        req0
      )

    {:ok, req, state}
  end
end
