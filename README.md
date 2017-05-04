# Layout

## Git Commit Notes

Development Snapshot

Redefined the Layout structure. Elements is now list of %Layout{}.
Using struct really cleans up the code.

## Development

  - Allow the layout to nest layouts as children in the elements list.
  - Must add documentation. See 'test' function until then.
  - Use months on x-axis as a good documentation example.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `layout` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:layout, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/layout](https://hexdocs.pm/layout).
