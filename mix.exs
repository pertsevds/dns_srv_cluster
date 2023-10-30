defmodule DNSSRVCluster.MixProject do
  use Mix.Project

  @version "0.1.0"
  @scm_url "https://github.com/pertsevds/dns_srv_cluster"
  @maintainer "Dmitriy Pertsev"

  def project do
    [
      app: :dns_srv_cluster,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      package: package(),
      aliases: aliases(),
      test_coverage: [ignore_modules: [DNSSRVCluster.App.Default]],
      docs: docs(),
      deps: deps(),
      source_url: @scm_url,
      homepage_url: @scm_url,
      description: "Elixir clustering with DNS SRV records"
    ]
  end

  defp package do
    [
      maintainers: [@maintainer],
      licenses: ["MIT"],
      links: %{"GitHub" => @scm_url},
      files: ~w(lib LICENSE.md mix.exs README.md .formatter.exs)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DNSSRVCluster.App, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:styler, "~> 0.9", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md"
      ]
    ]
  end
end
