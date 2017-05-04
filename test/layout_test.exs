defmodule LayoutTest do
  use ExUnit.Case
  doctest Layout

  test "layout create" do
    state = Layout.create "hello"
    assert state.name == "hello"
  end

  test "add element" do
    state = Layout.create "hello"
    state = Layout.add_element state, "Element One", 5.0
    assert length(state.elements) == 1
  end

  test "resolve layout" do
    state = Layout.create "hello"
    state = Layout.add_element state, "Element One", 5.0
    state = Layout.resolve state, 10.0
    IO.inspect state
    assert state.scale == 2.0
  end

  test "transform" do
    state = Layout.create "hello"
    state = Layout.add_element state, "Element One", 5.0
    state = Layout.resolve state, 10.0
    t = Layout.transform state, "Element One", 0, 10
    p = Affine.map t, 5.0
    IO.puts "Value: #{p}"
    assert state.scale == 2.0
  end

end
