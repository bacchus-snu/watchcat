defmodule Token do
  @doc ~S"""
  Generate JWT authentication token with given secret.

  ## Example

      iex> {:ok, token} = Token.get_token("admin", "watchcat-secret")
      iex> token |> String.split(".") |> List.first()
      "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9"
  """
  def get_token(permission, secret) do
    header =
      %{"typ" => "JWT", alg: "HS256"}
      |> encode()

    payload =
      %{
        "iss" => "watchcat",
        "sub" => "Authentication token for API",
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "perm" => permission
      }
      |> encode()

    signature =
      :crypto.hmac(:sha256, secret, header <> "." <> payload)
      |> Base.encode64()
      |> String.replace("=", "")

    {:ok, header <> "." <> payload <> "." <> signature}
  rescue
    _ -> {:error, :badarg}
  end

  @doc ~S"""
  Extract payload from given token and secret.
  If the signature is invalid or the token is malformed, it returns error tuple.

  ## Examples

      iex> {:ok, token} = Token.get_token("admin", "cat")
      iex> {:ok, payload} = Token.get_payload(token, "cat")
      iex> payload |> Map.fetch!("perm")
      "admin"
      iex> Token.get_payload(token, "dog")
      {:error, :invalid_signature}
      iex> Token.get_payload("wow malformed token", "cat")
      {:error, :invalid_token}
  """
  def get_payload(token, secret) do
    [header_encoded, payload_encoded, signature_encoded] = token |> String.split(".")

    calculated_signature =
      :crypto.hmac(:sha256, secret, header_encoded <> "." <> payload_encoded)
      |> Base.encode64()
      |> String.replace("=", "")

    if calculated_signature == signature_encoded do
      payload =
        payload_encoded
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
