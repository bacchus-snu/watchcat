defmodule Client do
  use Application
  require ClientSupervisor

  def start(_type, _args) do
    init_cert()
    ClientSupervisor.start_link([])
  end

  defp init_cert() do
    private_path = Application.app_dir(:client, "private")
    File.mkdir_p!(private_path)

    cert = Path.join(private_path, "cert.pem")
    key = Path.join(private_path, "key.pem")

    # Create a new self-signed certificate if it does not already exist
    unless File.exists?(cert) and File.exists?(key) do
      System.cmd(
        "openssl",
        ["req",
         "-x509",
         "-newkey", "rsa:4096",
         "-keyout", key,
         "-out", cert,
         "-days", "365",
         "-nodes",
         "-batch",
         "-subj", "/C=KR/O=Bacchus/OU=group/CN=contact@bacchus.snucse.org"
        ])
    end
  end
end
