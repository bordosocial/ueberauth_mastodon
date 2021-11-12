defmodule UeberauthMastodon.MixProject do
  use Mix.Project

  def project do
    [
      app: :ueberauth_mastodon,
      version: "0.1.0",
      elixir: "~> 1.11",
      name: "ueberauth_mastodon",
      description: "Überauth strategy for Mastodon and Pleroma.",
      source_url: "https://gitlab.com/soapbox-pub/ueberauth_mastodon",
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitLab" => "https://gitlab.com/soapbox-pub/ueberauth_mastodon"}
    ]
  end

  def docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "LICENSE.md"
      ],
      groups_for_modules: groups_for_modules(),
      source_ref: "v0.1.0"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ueberauth, "~> 0.7.0"},
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.18"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.24.2", only: :dev, runtime: false}
    ]
  end

  defp groups_for_modules do
    []
  end
end
