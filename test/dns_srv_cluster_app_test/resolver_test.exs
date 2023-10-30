defmodule DNSSRVClusterAppTest.Resolver do
  @moduledoc false
  @nodes %{
    my_node: ~c"my_node.internal",
    already_known: ~c"already_known.internal",
    new: ~c"new.internal",
    no_connect_diff_base: ~c"no_connect_diff_base.internal"
  }

  @srv_records %{
    my_srv: {0, 10, 1_234, ~c"my_node.internal"},
    already_known: {0, 10, 1_234, ~c"already_known.internal"},
    new: {0, 10, 1_234, ~c"new.internal"},
    no_connect_diff_base: {0, 10, 1_234, ~c"no_connect_diff_base.internal"}
  }

  def list_connected_nodes do
    [:"app@#{@nodes.already_known}"]
  end

  def basename(_node_name), do: "app"

  def lookup(query, type) when is_binary(query) and type in [:srv] do
    rec1 = @srv_records.my_srv
    rec2 = @srv_records.already_known
    rec3 = @srv_records.new
    rec4 = @srv_records.no_connect_diff_base
    [rec1, rec2, rec3, rec4]
  end

  @new_node :"app@#{@nodes.new}"
  def connect_to(@new_node) do
    send(:DNSSRVClusterAppTest, {:try_connect, @new_node})
    {@new_node, true}
  end

  @no_connect_node :"app@#{@nodes.no_connect_diff_base}"
  def connect_to(@no_connect_node) do
    {@no_connect_node, false}
  end

  def my_node do
    :"app@#{@nodes.my_node}"
  end
end
