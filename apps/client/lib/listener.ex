defmodule Listener do
  use Task, restart: :permanent
  require Logger

  def start_link(args) do
    Task.start_link(__MODULE__, :accept, [args])
  end

  def accept(port) do
    ssl_dir = Application.app_dir(:client, "priv/ssl")
    cert = Path.join(ssl_dir, "cert.pem")
    key = Path.join(ssl_dir, "key.pem")
    cacert = Path.join(ssl_dir, "cacert.pem")
    server_domain = Application.get_env(:client, :general) |> Keyword.fetch!(:server_domain)

    opts = [
      :binary,
      packet: :line,
      active: false,
      reuseaddr: true,
      certfile: cert,
      keyfile: key,
      cacertfile: cacert,
      depth: 99,
      verify: :verify_peer,
      verify_fun: {&:ssl_verify_hostname.verify_fun/3, [check_hostname: server_domain]},
      fail_if_no_peer_cert: true
    ]

    :ok = :ssl.start()
    {:ok, listen_socket} = :ssl.listen(port, opts)

    accepter_loop(listen_socket)
  end

  defp accepter_loop(listen_socket) do
    with {:ok, socket} <- :ssl.transport_accept(listen_socket),
         :ok <- :ssl.ssl_accept(socket) do
      {:ok, pid} =
        Task.Supervisor.start_child(Listener.TaskSupervisor, fn -> serve_request(socket) end)

      :ssl.controlling_process(socket, pid)
      accepter_loop(listen_socket)
    else
      {:error, _reason} ->
        accepter_loop(listen_socket)
    end
  end

  defp serve_request(socket) do
    case :ssl.recv(socket, 0) do
      {:ok, data} ->
        try do
          handle_data(socket, data)
        rescue
          _ -> Logger.error("error when serving request")
        end

        serve_request(socket)

      {:error, _reason} ->
        nil
    end
  end

  defp handle_data(socket, packed_data) do
    [command | args] = unpack(packed_data)

    case command do
      "metric" ->
        # add timestamp key
        args = args ++ ["timestamp"]
        data = args |> Enum.map(&fetch_metric/1) |> Map.new() |> pack()
        :ssl.send(socket, data <> "\n")

      "command" ->
        data = args |> List.first() |> invoke_command() |> pack()
        :ssl.send(socket, data <> "\n")

      _ -> Logger.error("not supported command: " <> command)
    end
  end

  defp fetch_metric(key) do
    key_atom =
      case key do
        "cpu" -> :cpu
        "memory" -> :memory
        "disk" -> :disk
        "network" -> :network
        "uptime" -> :uptime
        "loadavg" -> :loadavg
        "userlist" -> :userlist
        "timestamp" -> :timestamp
      end

    {key, data} = :ets.lookup(:metric, key_atom) |> List.first()

    result =
      case data do
        {:ok, metric} ->
          %{"status" => "ok", "data" => metric}

        {:error, reason} ->
          %{"status" => "error", "reason" => reason}

        raw_data ->
          raw_data
      end

    {key, result}
  end

  defp invoke_command(command) when is_binary(command) do
    File.write!("_running_script", command)
    File.chmod!("_running_script", 0o774)
    {result, exit_code} = System.cmd("bash", ["_running_script"], stderr_to_stdout: true)
    File.rm!("_running_script")

    %{
      result: result,
      exit_code: exit_code
    }
  end

  defp pack(data) do
    data
    |> Msgpax.pack!()
    |> IO.iodata_to_binary()
    |> Base.encode64()
  end

  defp unpack(data) do
    data
    |> String.trim()
    |> Base.decode64!()
    |> Msgpax.unpack!()
  end
end
