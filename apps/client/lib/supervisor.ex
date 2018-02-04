defmodule ClientSupervisor do
  use Supervisor
  require PeriodicCollect
  require Listener

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    port = 10101

    children = [
      PeriodicCollect,
      {Task.Supervisor, name: Listener.TaskSupervisor},
      {Listener, port},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end

