defmodule Oracledbex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :oracledbex,
      version: "0.1.0",
      elixir: "~> 1.5",
      description: "Adapter to Oracle Database. Using DBConnection and ODBC",
      buil_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      #Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["test.local": :test,
                          "coveralls": :test,
                          "coveralls.travis": :test],
      #Docs
      name: "Oracledbex",
      source_url: "",
      docs: [main: "readme",
            extras: ["README.md"]]]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :odbc]
    ]
  end

  defp deps do
    [{:db_connection, "~> 1.1"},
     {:decimal, "~> 1.0"},
     {:ex_doc, "~> 0.15", only: :dev, runtime: false},
     {:excoveralls, "~> 0.6", only: :test},
     {:inch_ex, "~> 0.5", only: :docs},
     {:exfmt, "~> 0.4.0", only: :dev},
     # For pool connection
     {:poolboy, "~> 1.5", [optional: true]}
    ]
  end

  defp package do
    [name: :oracledbex,
     files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Eric Paul Flores"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => ""}]
  end

end
