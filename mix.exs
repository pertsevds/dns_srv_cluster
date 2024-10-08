defmodule DNSSRVCluster.MixProject do
  use Mix.Project

  @version "0.3.0"
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
      test_coverage: [tool: ExCoveralls, ignore_modules: [DNSSRVCluster.App.Default]],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      docs: docs(),
      deps: deps(),
      source_url: @scm_url,
      homepage_url: @scm_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Elixir clustering with DNS SRV records"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test, runtime: false},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false}
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
