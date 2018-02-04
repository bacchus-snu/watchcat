defmodule ClientSupervisor do
  use Supervisor
  require Collector
  require Listener

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    port = 10101

    children = [
      Collector,
      {Task.Supervisor, name: Listener.TaskSupervisor},
      {Listener, port},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end

