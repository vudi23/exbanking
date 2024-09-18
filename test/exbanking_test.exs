defmodule ExbankingTest do
  use ExUnit.Case
  doctest Exbanking

  test "greets the world" do
    assert Exbanking.hello() == :world
  end
end
