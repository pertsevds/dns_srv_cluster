defmodule DNSSRVClusterAppTest.NullResolver do
  @moduledoc false
  @nodes %{
    my_node: ~c"my_node.internal",
    already_known: ~c"already_known.internal",
    new: ~c"new.internal",
    no_connect_diff_base: ~c"no_connect_diff_base.internal"
  }

  def list_connected_nodes do
    []
  end

  def basename(_node_name), do: "app"

  def lookup(query, type) when is_binary(query) and type in [:srv] do
    []
  end

  def my_node do
    :"app@#{@nodes.my_node}"
  end
end
