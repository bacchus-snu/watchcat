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
          e in RuntimeError -> Logger.error(e.message)
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
        data = args |> Enum.map(&fetch_metric/1) |> Map.new() |> pack()
        :ssl.send(socket, data)

      _ ->
        :error
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
      end

    :ets.lookup(:metric, key_atom) |> List.first()
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
