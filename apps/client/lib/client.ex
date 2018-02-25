defmodule Client do
  use Application
  require ClientSupervisor

  def start(_type, _args) do
    init_cert()
    ClientSupervisor.start_link([])
  end

  defp init_cert() do
    cert_path = Application.app_dir(:client, "priv/client_cert")
    cert = Path.join(cert_path, "cert.pem")
    key = Path.join(cert_path, "key.pem")

    # Create a new self-signed certificate if it does not already exist
    unless File.exists?(cert) and File.exists?(key) do
      File.mkdir_p!(cert_path)

      {_, 0} =
        System.cmd("openssl", [
          "req",
          "-x509",
          "-newkey",
          "rsa:4096",
          "-keyout",
          key,
          "-out",
          cert,
          "-days",
          "365",
          "-nodes",
          "-batch",
          "-subj",
          "/C=KR/O=Bacchus/OU=group/CN=contact@bacchus.snucse.org"
        ])
    end
  end
end
