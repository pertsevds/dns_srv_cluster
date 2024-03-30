defmodule DNSSRVClusterAppTest do
  @moduledoc false
  use ExUnit.Case

  doctest DNSSRVCluster.App

  @nodes %{
    my_node: ~c"my_node.internal",
    already_known: ~c"already_known.internal",
    new: ~c"new.internal",
    no_connect_diff_base: ~c"no_connect_diff_base.internal"
  }

  defp wait_for_node_discovery(cluster) do
    :sys.get_state(cluster)
    :ok
  end

  defp prerun do
    Application.stop(:dns_srv_cluster)
    :ok = Application.start(:dns_srv_cluster)
  end

  defp postrun do
    Application.stop(:dns_srv_cluster)
  end

  test "discovers nodes" do
    Process.register(self(), :DNSSRVClusterAppTest)

    Application.put_all_env(
      dns_srv_cluster: [
        query: "_app._tcp.internal",
        resolver: DNSSRVClusterAppTest.Resolver
      ]
    )

    prerun()

    worker = DNSSRVCluster.get_pid()
    wait_for_node_discovery(worker)

    new_node = :"app@#{@nodes.new}"
    no_connect_node = :"app@#{@nodes.no_connect_diff_base}"
    assert_receive {:try_connect, ^new_node}
    refute_receive {:try_connect, ^no_connect_node}
    refute_receive _

    n1 = DNSSRVCluster.list_all_nodes(worker)
    n2 = DNSSRVCluster.list_connected_nodes(worker)
    n3 = DNSSRVCluster.list_unconnected_nodes(worker)

    assert n1 == [
             :"app@my_node.internal",
             :"app@already_known.internal",
             :"app@new.internal",
             :"app@no_connect_diff_base.internal"
           ]

    assert n2 == [:"app@already_known.internal"]
    assert n3 == [:"app@new.internal", :"app@no_connect_diff_base.internal"]

    postrun()
  end

  test "query with :ignore does not start worker" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: :ignore
      ]
    )

    prerun()

    assert DNSSRVCluster.get_pid() == nil

    postrun()
  end

  test "Emits warning if DNS records was not found" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: "_app._tcp.nonexistent.domain",
        resolver: DNSSRVClusterAppTest.NullResolver
      ]
    )

    Application.stop(:dns_srv_cluster)

    res =
      ExUnit.CaptureLog.capture_log(fn ->
        :ok = Application.start(:dns_srv_cluster)
        :sys.get_state(DNSSRVCluster.get_pid())
      end)

    assert res =~ "not found"

    postrun()
  end

  test "discover nodes without query fails" do
    Application.delete_env(:dns_srv_cluster, :query)

    Application.stop(:dns_srv_cluster)
    assert match?({:error, _}, Application.start(:dns_srv_cluster))

    postrun()
  end

  test "discover nodes query must be a string" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: []
      ]
    )

    Application.stop(:dns_srv_cluster)
    assert match?({:error, _}, Application.start(:dns_srv_cluster))

    postrun()
  end

  test "Handle lookup error" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: "_app._tcp.nonexistent.domain",
        resolver: DNSSRVClusterAppTest.ErrResolver
      ]
    )

    Application.stop(:dns_srv_cluster)

    res =
      ExUnit.CaptureLog.capture_log(fn ->
        :ok = Application.start(:dns_srv_cluster)
        :sys.get_state(DNSSRVCluster.get_pid())
      end)

    assert res =~ "not found"

    postrun()
  end

  # test "without distribution the warning message is printed" do

end
