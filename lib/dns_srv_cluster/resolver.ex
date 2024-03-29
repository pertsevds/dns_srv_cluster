defmodule DNSSRVCluster.Resolver do
  @moduledoc false
  require Logger
  require Record

  Record.defrecord(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  # Public

  @spec basename(atom()) :: binary()
  def basename(node_name) when is_atom(node_name) do
    [basename, _] =
      node_name
      |> to_string()
      |> String.split("@")

    basename
  end

  @spec connect_to(atom()) :: {atom(), false | :ignored | true}
  def connect_to(node_name) when is_atom(node_name), do: {node_name, Node.connect(node_name)}

  @spec list_connected_nodes() :: [atom()]
  def list_connected_nodes, do: Node.list(:visible)

  def lookup(query, type) when is_binary(query) and type in [:srv] do
    case :inet_res.getbyname(~c"#{query}", type) do
      {:ok, hostent(h_addr_list: addr_list)} ->
        addr_list

      {:error, _} ->
        Logger.warning(~s(inet_res.getbyname for query "#{query}" with type "#{type}"failed.))
        []
    end
  end

  @spec my_node() :: atom()
  def my_node, do: node()
end
