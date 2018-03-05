defmodule HTTPHandler do
  def get_permission(req) do
    [secret: secret] = :ets.lookup(:secret, :secret)

    {:ok, payload} =
      :cowboy_req.header("authentication", req)
      |> Token.get_payload(secret)

    payload |> Map.get("perm", "normal")
  rescue
    _ ->
    "normal"
  end
end

defmodule HTTPHandler.MetricReq do
  import Ex2ms

  def init(req0 = %{method: "GET"}, state) do
    encode_metric = fn {name, metric_data} ->
      case metric_data do
        {:ok, metric} ->
          %{"name" => name, "status" => "ok", "data" => metric}

        {:error, reason} ->
          %{"name" => name, "status" => "error", "reason" => reason}
      end
    end

    machine_name = :cowboy_req.binding(:machine_name, req0)

    {code, contents} =
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
      case code do
        200 ->
          {"application/json", contents |> Poison.encode!()}

        _ ->
          {"text/plain", contents}
      end

    req =
      :cowboy_req.reply(
        code,
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

defmodule HTTPHandler.MachineReq do
  import Ex2ms

  def init(req0 = %{method: "GET"}, state) do
    machines =
      :dets.select(
        :clients,
        fun do
          {x, y} -> y
        end
      )

    update = fn x -> Map.update!(x, "host", &to_string/1) end

    contents =
      machines
      |> Enum.map(update)
      |> Poison.encode!()

    req =
      :cowboy_req.reply(
        200,
        %{"content-type" => "application/json"},
        contents,
        req0
      )

    {:ok, req, state}
  end

  def init(req0 = %{method: "POST"}, state) do
    permission = req0 |> HTTPHandler.get_permission()

    if permission != "admin" do
      req = :cowboy_req.reply(403, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
    else
      {:ok, body, req1} = :cowboy_req.read_body(req0, %{length: 1024})
      contents = body |> Poison.decode!()
      %{"name" => name, "host" => host} = contents
      host = host |> to_charlist()
      tags = contents |> Map.get("tags", [])

      general_config = Application.get_env(:server, :general)
      network_config = Application.get_env(:server, :network)
      port = network_config |> Keyword.fetch!(:client_port)
      timeout = network_config |> Keyword.fetch!(:timeout)
      cert_path = general_config |> Keyword.fetch!(:cert_path)
      key_path = general_config |> Keyword.fetch!(:key_path)
      cacert_path = Application.app_dir(:server, "priv") |> Path.join("cacert.pem")

      opts = [
        active: false,
        verify: :verify_none,
        certfile: cert_path,
        keyfile: key_path,
        cacertfile: cacert_path
      ]

      result =
        with {:ok, socket} <- :ssl.connect(host, port, opts, timeout),
             {:ok, cert} <- :ssl.peercert(socket),
             hash <- :crypto.hash(:sha256, cert) do
          {:ok, hash |> Base.encode16()}
        else
          _ -> {:error, :connection_failure}
        end

      req =
        case result do
          {:ok, fingerprint} ->
            body = %{"name" => name, "host" => host, "fingerprint" => fingerprint, "tags" => tags}
            true = :dets.insert_new(:clients, {name, body})

            response_body =
              body
              |> Map.update!("host", &to_string/1)
              |> Poison.encode!()

            :cowboy_req.reply(201, %{"content-type" => "application/json"}, response_body, req1)

          {:error, :connection_failure} ->
            :cowboy_req.reply(404, %{"content-type" => "text/plain"}, "", req1)

          {:error, _} ->
            :cowboy_req.reply(400, %{"content-type" => "text/plain"}, "", req1)
        end

      {:ok, req, state}
    end
  rescue
    _ ->
      req = :cowboy_req.reply(400, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
  end

  def init(req0 = %{method: "DELETE"}, state) do
    permission = req0 |> HTTPHandler.get_permission()

    if permission != "admin" do
      req = :cowboy_req.reply(403, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
    else
      {:ok, body, req1} = :cowboy_req.read_body(req0, %{length: 1024})
      %{"name" => name} = body |> Poison.decode!()
      :ok = :dets.delete(:clients, name)
      req = :cowboy_req.reply(204, %{"content-type" => "text/plain"}, "", req1)
      {:ok, req, state}
    end
  rescue
    _ ->
      req = :cowboy_req.reply(400, %{"content-type" => "text/plain"}, "", req0)
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

defmodule HTTPHandler.MachineTagReq do
  def init(req0 = %{method: "PUT"}, state) do
    permission = req0 |> HTTPHandler.get_permission()

    if permission != "admin" do
      req = :cowboy_req.reply(403, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
    else
      {:ok, body, req1} = :cowboy_req.read_body(req0, %{length: 1024})
      new_tags = body |> Poison.decode!()

      machine_name = :cowboy_req.binding(:machine_name, req1)
      [{^machine_name, old}] = :dets.lookup(:clients, machine_name)
      new = old |> Map.put("tags", new_tags)

      :ok = :dets.insert(:clients, {machine_name, new})

      req = :cowboy_req.reply(200, %{"content-type" => "text/plain"}, "", req1)
      {:ok, req, state}
    end
  rescue
    _ ->
      req = :cowboy_req.reply(400, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
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
