defmodule Mix.Tasks.AdminToken do
  use Mix.Task

  @shortdoc "Issues administrator token for API"
  def run(_) do
    priv_path = Application.app_dir(:server, "priv")
    secret_key_path = Path.join(priv_path, "secret_key")

    if File.exists?(secret_key_path) do
      secret_key = File.read!(secret_key_path)
      {:ok, token} = Token.get_token("admin", secret_key)
      IO.puts(token)
    else
      IO.puts("There is no secret key. Please generate it first.")
    end
  end
end
