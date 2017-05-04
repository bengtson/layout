defmodule LayoutTest do
  use ExUnit.Case
  doctest Layout

  test "layout create" do
    state = Layout.create "hello", 10.0
    assert state.name == "hello"
  end

  test "add element" do
    state = Layout.create "hello", 10.0
    state = Layout.add_element state, "Element One", 5.0
    assert length(state.elements) == 1
  end

  test "resolve layout" do
    state = Layout.create "hello", 10.0
    state = Layout.add_element state, "Element One", 5.0
    state = Layout.resolve state
    %{length: length, start: start} = hd(state.elements)
    assert length == 10.0
    assert start == 0.0
  end

  test "transform" do
    state = Layout.create "hello", 30.0
    state = Layout.add_element state, "Element Two", 5.0
    state = Layout.add_element state, "Element Three", 10.0
    state = Layout.resolve state
    t = Layout.transform state, "Element Three", 0, 5
    assert Affine.map(t, 0.0) == 10.0
    assert Affine.map(t, 5.0) == 30.0
  end

  test "calendar months" do
    transform =
      Layout.create("calendar axis", 150.0)
        |> Layout.add_element("left margin", 15.0)
        |> Layout.add_element("months", 120.0)
        |> Layout.add_element("right margin", 15.0)
        |> Layout.resolve
        |> Layout.transform("months", -0.5, 12.0)

    assert Affine.map(transform,0.0) == 20.0
    assert Affine.map(transform,0.5) == 25.0
    assert Affine.map(transform,9.0) == 110.0
  end

end
