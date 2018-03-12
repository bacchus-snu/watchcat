defmodule API.Metric do
  def init(req0 = %{method: "GET"}, state) do
    permission = req0 |> API.get_permission()
    encode_metric = fn {name, metric_data} ->
      case metric_data do
        {:ok, metric} ->
          if permission == "admin" do
            %{"name" => name, "status" => "ok", "data" => metric}
          else
            %{"name" => name, "status" => "ok", "data" => metric |> Map.delete("userlist")}
          end

        {:error, reason} ->
          %{"name" => name, "status" => "error", "reason" => reason}
      end
    end

    machine_name = :cowboy_req.binding(:machine_name, req0)

    {status_code, contents} =
      case machine_name do
        # /api/metric
        :undefined ->
          machine_metrics =
            :ets.match_object(:client_metrics, :_)
            |> Enum.map(encode_metric)
          {200, machine_metrics}

        # /api/metric/<machine_name>
        machine_name ->
          case :ets.lookup(:client_metrics, machine_name) do
            [machine_metric] ->
              {200, machine_metric |> encode_metric.()}

            _ ->
              {404, ""}
          end
      end

    {type, contents} =
      case status_code do
        200 ->
          {"application/json", contents |> Poison.encode!()}

        _ ->
          {"text/plain", contents}
      end

    req =
      :cowboy_req.reply(
        status_code,
        %{"content-type" => type},
        contents,
        req0
      )

    {:ok, req, state}
  end

  # fall back other method
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
