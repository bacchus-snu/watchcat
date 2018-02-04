defmodule Listener do
  use Task, restart: :permanent
  require Logger

  def start_link(args) do
    Task.start_link(__MODULE__, :accept, [args])
  end

  def accept(port) do
    opts = [
      :binary,
      packet: :line,
      active: false,
      reuseaddr: true,
    ]

    {:ok, socket} = :gen_tcp.listen(port, opts)

    accepter_loop(socket)
  end

  defp accepter_loop(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, incoming} ->
        {:ok, pid} = Task.Supervisor.start_child(
          Listener.TaskSupervisor,
          fn -> serve_request(incoming) end
        )
        :ok = :gen_tcp.controlling_process(incoming, pid)
        accepter_loop(socket)
      {:error, _reason} ->
        Logger.info "error occurred in accept()"
        accepter_loop(socket)
    end
  end

  defp serve_request(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        handle_data(data)
        serve_request(socket)
      {:error, _reason} -> nil
    end
  end

  defp handle_data(packed_data) do
    [command | args] = unpack(packed_data)
    case command do
      "metric" ->
        :not_implemented
      _ ->
        :error
    end
  end

  defp unpack(data) do
    data
    |> Base.decode64!()
    |> Msgpax.unpack!()
  end
end
