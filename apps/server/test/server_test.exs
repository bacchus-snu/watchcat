defmodule ServerTest do
  use ExUnit.Case
  doctest Server

  # TODO: write some tests!
  test "greets the world" do
    assert Server.hello() == :world
  end
end
