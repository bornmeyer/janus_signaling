defmodule CallProtocolTest do
  use ExUnit.Case
  doctest CallProtocol

  test "greets the world" do
    assert CallProtocol.hello() == :world
  end
end
