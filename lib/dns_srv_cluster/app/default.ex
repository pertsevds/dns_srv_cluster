defmodule DNSSRVCluster.App.Default do
  @moduledoc false
  defmacro interval do
    5_000
  end

  defmacro connect_timeout do
    10_000
  end

  defmacro resolver do
    DNSSRVCluster.Resolver
  end
end
