defmodule DNSSRVCluster.Resolver do
  @moduledoc false

  # Public

  @spec basename(atom()) :: binary()
  def basename(node_name) when is_atom(node_name) do
    [basename, _] = String.split(to_string(node_name), "@")
    basename
  end

  @spec connect_to(atom()) :: {atom(), false | :ignored | true}
  def connect_to(node_name) when is_atom(node_name), do: {node_name, Node.connect(node_name)}

  @spec list_connected_nodes() :: [atom()]
  def list_connected_nodes, do: Node.list(:visible)

  def lookup(query, type) when is_binary(query) and type in [:srv] do
    :inet_res.lookup(~c"#{query}", :in, type)
  end

  @spec my_node() :: atom()
  def my_node do
    node()
  end
end
