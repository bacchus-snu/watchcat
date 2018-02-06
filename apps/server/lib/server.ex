defmodule Server do
  use Application
  require ServerSupervisor

  def start(_type, _args) do
    router = :cowboy_router.compile([
      {:"_", [
        {"/api/metric/[:machine]", HTTPHandler.MetricReq, []},
        {"/api/machines", HTTPHandler.MachineReq, []},
      ]}
    ])
    {:ok, _} = :cowboy.start_clear(
      :api_server,
      [port: 10102],
      %{env: %{dispatch: router}}
    )

    ServerSupervisor.start_link([])
  end
end
