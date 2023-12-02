defmodule Jop.Mixfile do
  use Mix.Project

  @version "0.1.0"
  def project do
    [
      app: :jop,
      version: @version,
      elixir: ">= 1.14.1",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "Superls",
        source_ref: "v#{@version}",
        source_url: "https://github.com/bougueil/superls"
      ]
    ]
  end

  def application do
    [
      extra_applications: [
        :logger
        # , :os_mon
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.30", only: [:docs, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
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
