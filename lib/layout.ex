defmodule Layout do
  use GenServer

  @moduledoc """
  Box is a layout manager that is initially focussed on assisting with
  charts and graphs. It's a GenServer since it needs to hold state.

  Need to have an elegant chart layout capability. SVG origin is top left.

      Layout.Box.new("chart")
      |> Box.set_size("chart", {400, 200})
      |> Box.add_element("chart", {:x, 2.0, "margin-left"})
      |> Box.add_element("chart", {:x, 5.0, "y-axis-label")
      |> Box.add_element("chart", {:x, 10.0, "y-axis")
      |> Box.add_element("chart", {:x, 80.0, "chart")
      |> Box.add_element("chart", {:x, 2.0, "margin-right")
      |> Box.add_element("chart", {:y, 2.0, "margin-top")
      |> Box.add_element("chart", {:y, 5.0, "chart-title")
      |> Box.add_element("chart", {:y, 10.0, "margin")
      |> Box.add_element("chart", {:y, 80.0, "chart")
      |> Box.add_element("chart", {:y, 2.0, "x-axis")
      |> Box.add_element("chart", {:y, 5.0, "x-axis-label")
      |> Box.add_element("chart", {:y, 2.0, "margin")

      Box.set_map(dir: :x, name: "chart", start: 0, stop: 150)
      x_map = Box.get_map(dir: :x, name: "chart")

  """

  # --------- GenServer Startup Functions

    @doc """
    Starts the GenServer.
    """
    def start_link do
      {:ok, _} = GenServer.start_link(__MODULE__, :ok, [name: Layouts])
    end

    @doc """
    Initialization simply sets an empty state. In this case, we have no
    boxes. Each new box defined will add an entry to the state with the
    key as the box name and the value as the state for the box.
    """
    def init (:ok) do
      {:ok, %{}}
    end

    def test do
      new("chart-x")
      |> set_width(400)
      |> add_element("margin-left",  2.0)
      |> add_element("y-axis-label", 5.0)
      |> add_element("y-axis",      10.0)
      |> add_element("chart",       80.0)
      |> add_element("margin-right", 2.0)
      |> resolve

      new("chart-y")
      |> set_width(200)
      |> add_element("margin-top",   2.0)
      |> add_element("chart-title",  5.0)
      |> add_element("margin",      10.0)
      |> add_element("chart",       80.0)
      |> add_element("x-axis",       2.0)
      |> add_element("x-axis-label", 5.0)
      |> add_element("margin",       2.0)
      |> resolve

      map = get_transform("chart-x","chart",0.0,100.0)
      p = Affine.map map, 0.0
      IO.inspect p
      p = Affine.map map, 100.0
      IO.inspect p
    end
  # --------- Client APIs

  @doc """
  New generates the state for a new box and places the state in the server.
  Returns {:error, :exists) if the box already exists.
  """
  def new name do
    GenServer.call Boxes, {:new, name}
  end

  @doc """
  Sets the x and y size of the box.
  """
  def set_width box_name, width do
    GenServer.call Boxes, {:set_width, box_name, width}
  end

  @doc """
  Adds a new element to either the x or y direction. The name is not required
  if it does not need to be referenced. The element is appended to any other
  elements that have been added.
  """
  def add_element box_name, name, width do
    GenServer.call Boxes, {:add_element, box_name, name, width}
  end

  @doc """
  Resolves the positions of each element in the box.
  """
  def resolve box_name do
    GenServer.call Boxes, {:resolve, box_name}
  end

  @doc """
  Returns an Affine 2D mapper for the specified area.
  """
  def get_transform box_name, element_name, start, stop do
    GenServer.call Boxes, {:get_transform, box_name, element_name, start, stop}
  end

  @doc """
  Deletes the specified box from the server.
  """
  def delete_box name do
    GenServer.call Boxes, {:delete, name}
  end

  # --------- GenServer Callbacks

  @doc """
  Adds the new box to the server. returns the state for the box, or error if
  it already exists.
  """
  def handle_call({:new, box_name}, _from, state) do
    case Map.has_key? state, box_name do
      true ->
        {:reply, {:error, :exists}, state}
      false ->
        box_state = %{elements: []}
        state = Map.merge state, %{box_name => box_state}
        {:reply, box_name, state}
    end
  end

  @doc """
  Sets the width parameter for the layout.
  """
  def handle_call({:set_width, box_name, width}, _from, state) do
    box_state = Map.fetch! state, box_name
    box_state = Map.merge box_state, %{width: width}
    state = Map.merge state, %{box_name => box_state}
    {:reply, box_name, state}
  end

  @doc """
  Adds a new element to the box in the specified direction. The element is
  appended to other elements already added.
  """
  def handle_call({:add_element, box_name, name, width},_from, state) do
    box_state = Map.fetch! state, box_name
    elements = box_state[:elements]
    elements = elements ++ [%{relative_width: width, name: name}]
    box_state = Map.merge box_state, %{elements: elements}
    state = Map.merge state, %{box_name => box_state}
    {:reply, box_name, state}
  end

  @doc """
  Resolves the positions of each element in the box.
  """
  def handle_call({:resolve, box_name}, _from, state) do
    box_state = Map.fetch! state, box_name
    total_r_width =
      box_state[:elements]
      |> Enum.reduce(0.0,fn(%{relative_width: width},acc) -> acc+width end)
    width = box_state[:width]
    scale = width/total_r_width

    elements =
      box_state[:elements]
      |> Enum.scan(%{start: 0.0, width: 0.0, scale: scale}, &element_resolve/2)

    box_state = Map.merge box_state, %{elements: elements}
    box_state = Map.merge box_state, %{total_relative_width: total_r_width}

    # scan elements adding start and width to each element.
    state = Map.merge state, %{box_name => box_state}
    {:reply, box_name, state}
  end

  @doc """
  Returns a transform for the specified layout and element.
  """
  def handle_call({:get_transform, layout_name, element_name, start, stop}, _from, state) do
    element =
      state[layout_name][:elements]
      |> Enum.find(fn(x) -> resp = Map.fetch(x, :name); resp == {:ok, element_name} end)
    x1_out = element[:start]
    x2_out = x1_out + element[:width]
    t = Affine.create [type: :linear_map, x1_in: start, x1_out: x1_out, x2_in: stop, x2_out: x2_out]

    {:reply, t, state}

  end

  @doc """
  Removes the specified box from the state.
  """
  def handle_call({:delete, name}, _from, state) do
    state = Map.delete state, name
    {:reply, :ok, state}
  end

  # --------- Private Support Functions

  defp element_resolve map_in, acc_in do
    start = acc_in[:start] + acc_in[:width]
    width = map_in[:relative_width] * acc_in[:scale]
    Map.merge map_in, %{start: start, width: width, scale: acc_in[:scale]}
  end

end
