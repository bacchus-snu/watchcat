defmodule ServerSupervisor do
  use Supervisor
  require ClientMetricCollector
  require APIServer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_args) do
    children = [
      ClientMetricCollector,
      {Task.Supervisor, name: ClientMetricCollector.Crawler},
      # more children...
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
