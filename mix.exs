defmodule UeberauthMastodon.MixProject do
  use Mix.Project

  def project do
    [
      app: :ueberauth_mastodon,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ueberauth, "~> 0.7.0"},
      {:oauth2, "~> 2.0"},
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.18"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.24.2", only: :dev, runtime: false}
    ]
  end
end
