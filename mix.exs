defmodule Jop.Mixfile do
  use Mix.Project

  @source_url "https://github.com/bougueil/jop"
  @version "0.1.3"
  def project do
    [
      app: :jop,
      version: @version,
      elixir: "~> 1.15-dev",
      package: package(),
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      description: "an in-memory logger for spatial / temporal search",
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: [:docs, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["bougueil"],
      links: %{
        GitHub: @source_url
      }
    }
  end

  defp docs do
    [
      main: "Jop",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        {"README.md", title: "README"},
        "CHANGELOG.md"
      ]
    ]
  end

  defp aliases do
    [
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format",
        "credo",
        "dialyzer --unmatched_returns"
      ]
    ]
  end
end
