defmodule API do
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
