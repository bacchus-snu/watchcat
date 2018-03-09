defmodule ClientMetricCollectorTest do
  use ExUnit.Case

  test "should initialize ets table" do
    ClientMetricCollector.start_link([])
    refute :ets.info(:client_metrics) == :undefined
  end
end
