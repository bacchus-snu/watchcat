defmodule Client do
  use Supervisor
  require PeriodicCollect

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    children = [
      PeriodicCollect,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
