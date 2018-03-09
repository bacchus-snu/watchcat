defmodule API.Tag do
  def init(req0 = %{method: "PUT"}, state) do
    permission = req0 |> API.get_permission()

    if permission != "admin" do
      req = :cowboy_req.reply(403, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
    else
      {:ok, body, req1} = :cowboy_req.read_body(req0, %{length: 1024})
      new_tags = body |> Poison.decode!()
      true = is_list(new_tags) and Enum.all?(new_tags, &is_binary/1)

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

  def init(req0 = %{method: "POST"}, state) do
    permission = req0 |> API.get_permission()

    if permission != "admin" do
      req = :cowboy_req.reply(403, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
    else
      {:ok, body, req1} = :cowboy_req.read_body(req0, %{length: 1024})
      new_tag = body |> Poison.decode!()
      true = is_binary(new_tag)

      machine_name = :cowboy_req.binding(:machine_name, req1)
      [{^machine_name, old}] = :dets.lookup(:clients, machine_name)
      new_tags = [new_tag | old["tags"]] |> Enum.uniq()
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

  def init(req0 = %{method: "DELETE"}, state) do
    permission = req0 |> API.get_permission()

    if permission != "admin" do
      req = :cowboy_req.reply(403, %{"content-type" => "text/plain"}, "", req0)
      {:ok, req, state}
    else
      {:ok, body, req1} = :cowboy_req.read_body(req0, %{length: 1024})
      tag = body |> Poison.decode!()
      true = is_binary(tag)

      machine_name = :cowboy_req.binding(:machine_name, req1)
      [{^machine_name, old}] = :dets.lookup(:clients, machine_name)
      new_tags = old["tags"] |> List.delete(tag)
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
