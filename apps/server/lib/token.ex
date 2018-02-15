defmodule Token do
  def get_token(permission, secret) do
    header =
      %{"typ" => "JWT", "alg": "HS256"}
      |> encode()

    payload =
      %{
        "iss" => "watchcat",
        "sub" => "Authentication token for API",
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "perm" => permission,
      }
      |> encode()

    signature =
      :crypto.hmac(:sha256, secret, header <> "." <> payload)
      |> Base.encode64()
      |> String.replace("=", "")

    header <> "." <> payload <> "." <> signature
  end

  defp encode(data) do
    data
    |> Poison.encode!()
    |> Base.encode64()
    |> String.replace("=", "")
  end
end
