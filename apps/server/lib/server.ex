defmodule Server do
  use Application
  require ServerSupervisor

  def start(_type, _args) do
    ServerSupervisor.start_link([])
  end
end
