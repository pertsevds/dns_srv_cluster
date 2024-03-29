# Used by "mix format"

defmodule LocalFormat do
  @moduledoc false
  def format(styler_compat) when styler_compat in [:gt, :eq] do
    [
      plugins: [Styler],
      inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
    ]
  end

  def format(_) do
    [
      inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
    ]
  end
end

elixir_version = System.version()
styler_compat = Version.compare(elixir_version, "1.14.0")

LocalFormat.format(styler_compat)
