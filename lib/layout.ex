defmodule Layout do

  defstruct [
    name: nil,
    start: 0.0,
    length: 0.0,
    rstart: 0.0,
    rlength: 0.0,
    scale: 0.0,
    elements: []
  ]
  @moduledoc """
  Box is a layout manager that is initially focussed on assisting with
  charts and graphs. It's a GenServer since it needs to hold state.

  Need to have an elegant chart layout capability. SVG origin is top left.

      Layout.create("chart")
      |> Layout.add_element("margin-left", 2.0)
      |> Layout.add_element("y-axis-label", 5.0)
      |> Layout.add_element("y-axis", 10.0)
      |> Layout.add_element("chart", 80.0)
      |> Layout.add_element("margin-right", 2.0)
      |> Layout.resolve(400)

      map = get_transform("chart","chart", 0.0, 100.0)

  """

  @doc """
  Creates a new Layout with the given name. The Layout structure is returned
  and becomes the state for all other Layout calls. The caller may keep the
  state stored as they choose.
  """
  def create name do
    struct(%Layout{},
      name: name,
      )
  end

  @doc """
  Adds an element to the Layout. Each element requires a name and a relative
  length.
  """
  def add_element state, name, rlength do
    new_element = %Layout{name: name, rlength: rlength}
    struct(state, elements: state.elements ++ [new_element])
  end

  @doc """
  Once all elements have been defined, the resolve function fits all the
  elements with their relative lengths into the length specified. Each element
  will have an entry that is like this:

      %{name: name, rength: rength, start: start, length: length}
  """
  def resolve state, length do

    # Get the total relative length of each element.
    rlength =
      state.elements
      |> Enum.reduce(0.0,fn(%{rlength: rlength},acc) -> acc+rlength end)

    scale = length / rlength

    elements =
      state.elements
      |> Enum.scan(%{start: 0.0, length: 0.0, scale: scale}, &element_resolve/2)

    struct(state,
      length: length,
      rlength: rlength,
      scale: scale,
      elements: elements
    )

  end

  def transform state, name, start, length do
    element =
      state.elements
      |> Enum.find(fn(x) -> x.name == name end)
    x1_out = element.start
    x2_out = x1_out + element.length
    Affine.create [type: :linear_map, x1_in: start, x1_out: x1_out, x2_in: start+length, x2_out: x2_out]
  end

  defp element_resolve map_in, acc_in do
    start = acc_in.start + acc_in.length
    length = map_in.rlength * acc_in.scale
    struct(map_in, start: start, length: length, scale: acc_in.scale)
  end

end
