defmodule ClientTest do
  use ExUnit.Case
  doctest Client

  # TODO: write some tests!
  test "greets the world" do
    assert Client.hello() == :world
  end
end
