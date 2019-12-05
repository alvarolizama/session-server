defmodule SessionServerTest do
  use ExUnit.Case
  doctest SessionServer

  test "greets the world" do
    assert SessionServer.hello() == :world
  end
end
