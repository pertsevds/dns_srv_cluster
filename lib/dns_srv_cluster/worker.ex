defmodule DNSSRVCluster.Worker do
  @moduledoc """
  Main app worker

  You can use it in your own supervision tree if you want.
  """
  use GenServer

  alias DNSSRVCluster.App.Default

  require DNSSRVCluster.App.Default
  require Logger

  @default_interval Default.interval()
  @default_connect_timeout Default.connect_timeout()
  @default_resolver Default.resolver()

  # Public

  @doc false
  def start_link(args) when is_list(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Private

  defp connect_async([], _resolver, _timeout) do
    []
  end

  defp connect_async(nodes, resolver, timeout) do
    Task.async_stream(nodes, &resolver.connect_to(&1),
      max_concurrency: length(nodes),
      timeout: timeout
    )
  end

  defp schedule_next_poll(state) do
    unless is_nil(state.poll_timer), do: Process.cancel_timer(state.poll_timer, info: false)
    %{state | poll_timer: Process.send_after(self(), :do_discovery, state.interval)}
  end

  defp connect_nodes(nodes, resolver, timeout) do
    nodes
    |> connect_async(resolver, timeout)
    |> Enum.to_list()
    |> Enum.each(fn async_result ->
      case async_result do
        {:ok, {node_name, true}} ->
          Logger.info("#{node()} connected to \"#{node_name}\".")

        {:ok, {node_name, false}} ->
          Logger.warning("Connect to \"#{node_name}\" failed.")

        {:ok, {node_name, :ignored}} ->
          Logger.warning("Connect request to \"#{node_name}\" ignored. Looks like Erlang distribution is not enabled.")

        :error ->
          Logger.error("connect_nodes/3 Task async error.")
      end
    end)
  end

  defp get_name_from_srv_record({_, _, _, name}) do
    to_string(name)
  end

  defp list_all_nodes(resolver, query) do
    basename = resolver.basename(resolver.my_node())

    records = resolver.lookup(query, :srv)

    case records do
      {:ok, []} ->
        Logger.warning("DNS query `#{query}` has not found any records.")
        []

      {:ok, records} when is_list(records) ->
        Enum.map(records, fn srv ->
          node = get_name_from_srv_record(srv)
          :"#{basename}@#{node}"
        end)

      {:error, err} ->
        Logger.warning("DNS lookup failed with error: #{err}.")
        []
    end
  end

  defp do_discovery(state) do
    all_nodes = list_all_nodes(state.resolver, state.query)

    connected_nodes = state.resolver.list_connected_nodes()

    my_node = state.resolver.my_node()
    unconnected_nodes = all_nodes -- [my_node | connected_nodes]

    connect_nodes(unconnected_nodes, state.resolver, state.connect_timeout)

    schedule_next_poll(state)
  end

  defp get_net_state do
    if function_exported?(:net_kernel, :get_state, 0) do
      :net_kernel.get_state()
    end
  end

  defp warn_node_not_running_distributed_mode do
    Logger.warning("""
    Node not running in distributed mode. Ensure the following exports are set in your rel/env.sh.eex file:

        export RELEASE_DISTRIBUTION="${RELEASE_DISTRIBUTION:-"name"}"
        export RELEASE_NODE="${RELEASE_NODE:-"<%= @release.name %>"}"
    """)
  end

  defp warn_node_not_running_distributed_mode_with_longnames do
    Logger.warning("""
    Node not running in distributed mode. When running outside of a release, you must start net_kernel manually with
    longnames.
    https://www.erlang.org/doc/man/net_kernel.html#start-2
    """)
  end

  defp warn_on_invalid_dist do
    release? = is_binary(System.get_env("RELEASE_NAME"))
    net_state = get_net_state()

    case net_state do
      nil ->
        :ok

      %{started: :no} = _state when release? ->
        warn_node_not_running_distributed_mode()

      %{started: :no} = _state ->
        warn_node_not_running_distributed_mode_with_longnames()

      %{started: started, name_domain: :shortnames} = _state when started != :no ->
        warn_node_not_running_distributed_mode_with_longnames()

      # !release? and state.started != :no and state[:name_domain] != :longnames ->
      # warn_node_not_running_distributed_mode_with_longnames()

      # net_state.started == :no or (!release? and net_state.started != :no and net_state[:name_domain] != :longnames) ->
      #   Logger.warning("""
      #   Node not running in distributed mode. When running outside of a release, you must start net_kernel manually with
      #   longnames.
      #   https://www.erlang.org/doc/man/net_kernel.html#start-2
      #   """)

      # net_state[:name_domain] != :longnames and release? ->
      #   Logger.warning("""
      #   Node not running with longnames which are required for DNS discovery.
      #   Ensure the following exports are set in your rel/env.sh.eex file:

      #       export RELEASE_DISTRIBUTION="${RELEASE_DISTRIBUTION:-"name"}"
      #       export RELEASE_NODE="${RELEASE_NODE:-"<%= @release.name %>"}"
      #   """)

      _ ->
        :ok
    end
  end

  # Callbacks

  @impl GenServer
  def init(opts) do
    query = Keyword.fetch(opts, :query)

    case query do
      {:ok, :ignore} ->
        :ignore

      {:ok, query} when is_binary(query) ->
        warn_on_invalid_dist()

        state = %{
          connect_timeout: Keyword.get(opts, :connect_timeout, @default_connect_timeout),
          interval: Keyword.get(opts, :interval, @default_interval),
          poll_timer: nil,
          query: query,
          resolver: Keyword.get(opts, :resolver, @default_resolver)
        }

        {:ok, state, {:continue, :do_discovery}}

      :error ->
        {:stop, "`:query` was not found in arguments."}
    end
  end

  @impl GenServer
  def handle_continue(:do_discovery, state) do
    {:noreply, do_discovery(state)}
  end

  @impl GenServer
  def handle_info(:do_discovery, state) do
    {:noreply, do_discovery(state)}
  end

  @impl GenServer
  def handle_call(:list_all_nodes, _from, state) do
    all_nodes = list_all_nodes(state.resolver, state.query)
    {:reply, all_nodes, state}
  end

  @impl GenServer
  def handle_call(:list_connected_nodes, _from, state) do
    connected_nodes = state.resolver.list_connected_nodes()
    {:reply, connected_nodes, state}
  end

  @impl GenServer
  def handle_call(:list_unconnected_nodes, _from, state) do
    all_nodes = list_all_nodes(state.resolver, state.query)
    connected_nodes = state.resolver.list_connected_nodes()
    my_node = state.resolver.my_node()
    unconnected_nodes = all_nodes -- [my_node | connected_nodes]
    {:reply, unconnected_nodes, state}
  end
end
