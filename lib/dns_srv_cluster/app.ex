defmodule DNSSRVCluster.App do
  @moduledoc false
  use Application

  alias DNSSRVCluster.App.Default
  alias DNSSRVCluster.App.Env

  require DNSSRVCluster.App.Default
  require Logger

  @default_interval Default.interval()
  @default_connect_timeout Default.connect_timeout()
  @default_resolver Default.resolver()

  # Private

  defp dns_query do
    query = Env.fetch(:query)

    case query do
      {:ok, :ignore} ->
        {:ok, :ignore}

      {:ok, query} when is_binary(query) ->
        {:ok, query}

      {:error, var} ->
        {:error,
         """
         `#{var}` was not found in application config. \
         See README.md for examples.\
         """}

      _ ->
        {:error, "`query` must be a string or :ignore."}
    end
  end

  defp interval do
    Env.fetch(:interval, @default_interval)
  end

  defp connect_timeout do
    Env.fetch(:connect_timeout, @default_connect_timeout)
  end

  defp resolver do
    Env.fetch(:resolver, @default_resolver)
  end

  # Callbacks

  @impl Application
  def start(_type, _args) do
    query = dns_query()

    case query do
      {:ok, query} ->
        child_spec =
          [
            {DNSSRVCluster.Worker,
             query: query, interval: interval(), connect_timeout: connect_timeout(), resolver: resolver()}
          ]

        opts = [strategy: :one_for_one, name: DNSSRVCluster.Supervisor]
        Supervisor.start_link(child_spec, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
