defmodule DNSSRVClusterWorkerTest do
  @moduledoc false
  use ExUnit.Case

  doctest DNSSRVCluster.Worker

  # Additional tests for runtime: false use case

  test "We can use DNSSRVCluster.Worker without application" do
    children = [
      {DNSSRVCluster.Worker, query: "_app._tcp.yourdomain.com", resolver: DNSSRVClusterAppTest.Resolver}
    ]

    res = Supervisor.start_link(children, strategy: :one_for_one)

    assert match?({:ok, _}, res)

    {:ok, sup} = res

    :ok = Supervisor.stop(sup)
  end

  test "DNSCluster.Worker fail without query" do
    assert match?({:error, _}, start_supervised(DNSSRVCluster.Worker))
  end
end
