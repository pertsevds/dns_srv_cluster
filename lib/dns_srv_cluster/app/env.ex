defmodule DNSSRVCluster.App.Env do
  @moduledoc false
  def fetch(env_var) do
    res = Application.fetch_env(:dns_srv_cluster, env_var)

    case res do
      {:ok, var} -> {:ok, var}
      :error -> {:error, env_var}
    end
  end

  def fetch(env_var, default) do
    res = Application.fetch_env(:dns_srv_cluster, env_var)

    case res do
      {:ok, var} -> var
      :error -> default
    end
  end
end
