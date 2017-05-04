defmodule Layout do
  @moduledoc """
  The Layout module helps solve some of the difficulties in creating charts
  and graphs. It provides an easy approach to defining the various parts of
  charts such as axis, plot area, gridlines, titles, etc.

  A layout is simply a list of each chart area in one direction. For an X/Y
  chart, two layouts can be used to define the structure of the chart. Take for
  example creating an SVG chart showing lake levels (Y) by month (X). The
  elements of this chart in the x direction might consist of the following
  parts:

    - a left margin between the left edge of the SVG and the start of the chart.
    - an area that will show the title of the y-axis with text rotated 90°.
    - an area for the display of the labels for each gridline in the chart.
    - the plot area for the lake level data
    - a right margin between the right edge of the SVG and the right of the
      chart.

  With a well defined width of the chart, the widths of each area could be
  specified and then used for drawing text, labels, ticks, gridlines and data.
  However, it becomes difficult to make all the changes should the canvas be
  sized differently or if other chart parameters need to change.

  Here's an example of how to setup a Layout for the horizontal direction in
  the chart above. Let's assume that the width of the SVG canvas is going to
  be 800. The Layout generation might look something like this.

      layout =
        Layout.create("chart horizontal", 800)
        |> Layout.add("left margin", 2.0)
        |> Layout.add("y axis title", 10.0)
        |> Layout.add("y axis labels", 20.0)
        |> Layout.add("plot area", 75.0)
        |> Layout.add("right margin", 2.0)
        |> Layout.resolve

  The code shows the creation of a layout with a layout name and the width of
  the canvas that will be used. This is followed by layout elements defined by
  the chart designer. Each element has a name and a relative length (width for
  the horizontal layout in this example). The specified widths are relative and
  are determined by their ratio in the total of the relative widths. This makes
  it easy to change the width of a single element without redistributing the
  width in other elements. In this case, the total relative widths add up to
  109.0. This means, for example, that the "plot area" will be 75.0/109 or 69%
  of the total chart width.

  The 'resolve' function traverses the layout and assigns starting points and
  lengths to each of the elements based on the width of the canvas and the
  relative lengths of each element.

  'layout' will contain the information about the layout and all it's elements.

  Now assume the 3-letter month abbreviations need to be placed under the plot
  area with each centered with space provided for the month. A simple Affine
  map can be generated that easily provides position information for each of
  the month names. Generation of the transform is as follows:

      x_map = Layout.transform layout, "plot area", -0.5, 12

  An Affine map is returned that will let the user know the center position for
  the months as follows:

      jan_pos = Affine.map x_map, 0
      sep_pos = Affine.map x_map, 9

  These values are the x position in the SVG space that should be used for
  writing the centered test.

  The Layout handles all the calculations to determine the start point and
  width of the plot area and the Affine map automatically 'maps' the start and
  length information to the area.

  Of course, a second layout needs to be generated for the vertical elements of
  the chart but this is done using the same method as the vertical. When done,
  plotting data is as easy as using the x_map and y_map to move from the data
  space to the canvas space.

  See also the `scalar` module that can be used to automatically generate x and
  y scales, tick marks and gridlines based on the data to be plotted.
  """

  defstruct name: nil, elements: [],
            start: 0.0, length: 0.0,
            rstart: 0.0, rlength: 0.0

  @doc """
  Adds an element to the Layout. Each element requires a name and a relative
  length.
  """
  def add_element(layout, name, rlength) do
    new_element = %Layout{name: name, rlength: rlength}
    struct(layout, elements: layout.elements ++ [new_element])
  end


  @doc """
  Creates a new Layout with the given name. The Layout structure is returned
  and becomes the state for all other Layout calls. The caller may keep the
  state stored as they choose. A name and a length must be provided.
  """
  def create(name, length) do
    struct(%Layout{},
      name: name,
      length: length,
      )
  end

  @doc """
  Returns the %Layout structure for the specified element. The structure
  contains start, length, relative start and relative length info.
  """
  def get_element(layout, name) do
    layout.elements
    |> Enum.find(fn(x) -> x.name == name end)
  end

  @doc """
  Once all elements have been defined, the resolve function fits all the
  elements with their relative lengths into the length specified in the
  create call. Each element is another %Layout{} structure.
  """
  def resolve(layout) do

    # Get the total relative length of each element.
    rlength =
      layout.elements
      |> Enum.reduce(0.0,fn(%{rlength: rlength},acc) -> acc+rlength end)

    # Calculate the scaler for the entire layout.
    scale = layout.length / rlength

    # Iterate through each element setting start and length based on rstart,
    # rlength and scale.
    elements =
      layout.elements
      |> Enum.scan(%Layout{start: 0.0, length: 0.0}, fn(element,acc) -> element_resolve element, acc, scale end)

    # Return the updated main structure with updated elements.
    struct(layout,
      rlength: rlength,
      elements: elements
    )
  end

  @doc """
  Creates an Affine map for the specified layout element. This Affine map
  returns the physical position in the element given the relative position in.
  """
  def transform(layout, name, start, length) do
    element =
      layout.elements
      |> Enum.find(fn(x) -> x.name == name end)
    x1_out = element.start
    x2_out = x1_out + element.length
    Affine.create [type: :linear_map, x1_in: start, x1_out: x1_out, x2_in: start+length, x2_out: x2_out]
  end

  # Given a new elenent in and the prior map with prior start and length, Return
  # an updated element with start, length and scale set.
  defp element_resolve map_in, acc_in, scale do
    start = acc_in.start + acc_in.length
    length = map_in.rlength * scale
    struct(map_in, start: start, length: length)
  end
end
