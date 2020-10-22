defmodule GeneralTest do
  use ExUnit.Case
  doctest General

  test "greets the world" do
    assert General.hello() == :world
  end
end
