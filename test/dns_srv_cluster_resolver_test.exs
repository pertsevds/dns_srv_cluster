defmodule DNSSRVCluster.ResolverTest do
  use ExUnit.Case

  doctest DNSSRVCluster.Resolver

  test "basename/1 returns the expected result" do
    assert DNSSRVCluster.Resolver.basename(:"app@my_node.internal") == "app"
  end

  test "connect_to/1 without distribution returns :ignored" do
    {node_name, result} = DNSSRVCluster.Resolver.connect_to(:some_node)
    assert node_name == :some_node
    assert result == :ignored
  end

  test "my_node/0 without distribution returns :nonode@nohost" do
    assert DNSSRVCluster.Resolver.my_node() == :nonode@nohost
  end
end
