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

  defp tests_cleanup do
    Application.stop(:dns_srv_cluster)
    System.delete_env("RELEASE_NAME")
    Application.delete_env(:dns_srv_cluster, :query)
    :net_kernel.stop()
  end

  setup do
    on_exit(&tests_cleanup/0)
    :ok
  end

  setup_all do
    {stdout, res} = System.cmd("epmd", ["-daemon"])

    if res == 0 do
      :ok
    else
      {:error, {res, stdout}}
    end
  end

  defp wait_for_node_discovery(cluster) do
    :sys.get_state(cluster)
    :ok
  end

  test "discovers nodes" do
    Process.register(self(), :DNSSRVClusterAppTest)

    Application.put_all_env(
      dns_srv_cluster: [
        query: "_app._tcp.internal",
        resolver: DNSSRVClusterAppTest.Resolver
      ]
    )

    :ok = Application.start(:dns_srv_cluster)

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
  end

  test "query with :ignore does not start worker" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: :ignore
      ]
    )

    :ok = Application.start(:dns_srv_cluster)

    assert DNSSRVCluster.get_pid() == nil
  end

  test "Emits warning if DNS records was not found" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: "_app._tcp.nonexistent.domain",
        resolver: DNSSRVClusterAppTest.NullResolver
      ]
    )

    res =
      ExUnit.CaptureLog.capture_log(fn ->
        :ok = Application.start(:dns_srv_cluster)
        :sys.get_state(DNSSRVCluster.get_pid())
      end)

    assert res =~ "not found"
  end

  test "discover nodes without query fails" do
    assert match?({:error, _}, Application.start(:dns_srv_cluster))
  end

  test "discover nodes query must be a string" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: []
      ]
    )

    assert match?({:error, _}, Application.start(:dns_srv_cluster))
  end

  test "lookup error warning is printed" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: "_app._tcp.nonexistent.domain",
        resolver: DNSSRVClusterAppTest.ErrResolver
      ]
    )

    res =
      ExUnit.CaptureLog.capture_log(fn ->
        :ok = Application.start(:dns_srv_cluster)
        :sys.get_state(DNSSRVCluster.get_pid())
      end)

    assert res =~ "DNS lookup failed with error: Lookup failed."
  end

  if function_exported?(:net_kernel, :get_state, 0) do
    test "running in release without distribution should print the warning message" do
      Application.put_all_env(
        dns_srv_cluster: [
          query: "_app._tcp.nonexistent.domain",
          resolver: DNSSRVClusterAppTest.NullResolver
        ]
      )

      System.put_env("RELEASE_NAME", "my_app")

      res =
        ExUnit.CaptureLog.capture_log(fn ->
          :ok = Application.start(:dns_srv_cluster)
          :sys.get_state(DNSSRVCluster.get_pid())
        end)

      assert res =~
               "Node not running in distributed mode. Ensure the following exports are set in your rel/env.sh.eex file:"
    end

    test "running outside of a release should print the warning message" do
      Application.put_all_env(
        dns_srv_cluster: [
          query: "_app._tcp.nonexistent.domain",
          resolver: DNSSRVClusterAppTest.NullResolver
        ]
      )

      res =
        ExUnit.CaptureLog.capture_log(fn ->
          :ok = Application.start(:dns_srv_cluster)
          :sys.get_state(DNSSRVCluster.get_pid())
        end)

      assert res =~ """
             [warning] Node not running in distributed mode. When running outside of a release, you must start net_kernel manually with
             longnames.
             """
    end

    test "running in release with short names distribution should print the warning message" do
      Application.put_all_env(
        dns_srv_cluster: [
          query: "_app._tcp.nonexistent.domain",
          resolver: DNSSRVClusterAppTest.NullResolver
        ]
      )

      System.put_env("RELEASE_NAME", "my_app")

      res =
        ExUnit.CaptureLog.capture_log(fn ->
          {:ok, pid} = Node.start(:my_node, :shortnames)
          :ok = Application.start(:dns_srv_cluster)
          :sys.get_state(DNSSRVCluster.get_pid())
        end)

      assert res =~ """
             Node not running with longnames which are required for DNS discovery.
             Ensure the following exports are set in your rel/env.sh.eex file:
             """
    end

    test "running out of a release with short names distribution should print the warning message" do
      Application.put_all_env(
        dns_srv_cluster: [
          query: "_app._tcp.nonexistent.domain",
          resolver: DNSSRVClusterAppTest.NullResolver
        ]
      )

      res =
        ExUnit.CaptureLog.capture_log(fn ->
          {:ok, pid} = Node.start(:my_node, :shortnames)
          :ok = Application.start(:dns_srv_cluster)
          :sys.get_state(DNSSRVCluster.get_pid())
        end)

      assert res =~ """
             Node not running with longnames which are required for DNS discovery.
             See: https://hexdocs.pm/elixir/Node.html#start/3
             """
    end

    test "running out of a release with long names distribution should not print any warning messages" do
      Application.put_all_env(
        dns_srv_cluster: [
          query: "_app._tcp.nonexistent.domain",
          resolver: DNSSRVClusterAppTest.NullResolver
        ]
      )

      res =
        ExUnit.CaptureLog.capture_log(fn ->
          {:ok, pid} = Node.start(:my_node, :longnames)
          :ok = Application.start(:dns_srv_cluster)
          :sys.get_state(DNSSRVCluster.get_pid())
        end)

      refute res =~ "Node not running"
    end
  end

  test "running in release with long names distribution should not print any warning messages" do
    Application.put_all_env(
      dns_srv_cluster: [
        query: "_app._tcp.nonexistent.domain",
        resolver: DNSSRVClusterAppTest.NullResolver
      ]
    )

    System.put_env("RELEASE_NAME", "my_app")

    res =
      ExUnit.CaptureLog.capture_log(fn ->
        {:ok, pid} = Node.start(:my_node, :longnames)
        :ok = Application.start(:dns_srv_cluster)
        :sys.get_state(DNSSRVCluster.get_pid())
      end)

    refute res =~ "Node not running"
  end
end
