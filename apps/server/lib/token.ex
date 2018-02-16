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

  def get_payload(token, secret) do
    [header_encoded, payload_encoded, signature_encoded] =
      token |> String.split(".")

    calculated_signature =
      :crypto.hmac(:sha256, secret, header_encoded <> "." <> payload_encoded)
      |> Base.encode64()
      |> String.replace("=", "")

    if calculated_signature == signature_encoded do
      payload = payload_encoded
      |> Base.decode64!()
      |> Poison.decode!()
      {:ok, payload}
    else
      {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :invalid_token}
  end

  defp encode(data) do
    data
    |> Poison.encode!()
    |> Base.encode64()
    |> String.replace("=", "")
  end
end
