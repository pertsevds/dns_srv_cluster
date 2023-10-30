defmodule DNSSRVCluster do
  @moduledoc """
  App functions
  """

  @doc """
  Get pid of application worker.
  """
  def get_pid do
    Process.whereis(DNSSRVCluster.Worker)
  end

  @doc """
  Get list of all nodes that exist in DNS SRV record.
  """
  def list_all_nodes(pid) do
    GenServer.call(pid, :list_all_nodes)
  end

  @doc """
  Get list of connected nodes.
  """
  def list_connected_nodes(pid) do
    GenServer.call(pid, :list_connected_nodes)
  end

  @doc """
  Get list of nodes that are not connected.
  """
  def list_unconnected_nodes(pid) do
    GenServer.call(pid, :list_unconnected_nodes)
  end
end
