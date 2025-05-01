defmodule Jop.Mixfile do
  use Mix.Project

  @version "0.1.1"
  def project do
    [
      app: :jop,
      version: @version,
      elixir: "~> 1.15-dev",
      package: package(),
      start_permanent: Mix.env() == :prod,
      description: "an in-memory loggger for spatial / temporal search",
      deps: deps(),
      docs: [
        main: "Jop",
        source_ref: "v#{@version}",
        source_url: "https://github.com/bougueil/jop"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.37", only: [:docs, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Renaud Mariana"],
      links: %{"GitHub" => "https://github.com/bougueil/jop"}
    }
  end
end
