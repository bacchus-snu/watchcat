defmodule Client do
  use Application
  require ClientSupervisor

  def start(_type, _args) do
    ClientSupervisor.start_link([])
  end
end
