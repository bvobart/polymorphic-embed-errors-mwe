defmodule PolymorphicEmbedErrorsMwe.MixProject do
  use Mix.Project

  def project do
    [
      app: :polymorphic_embed_errors_mwe,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        # treat warnings as errors when compiling, so that references to undefined functions will also break the build
        warnings_as_errors: true
      ],
      deps: deps()
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.12.0"},
      {:polymorphic_embed, "~> 5.0"}
    ]
  end
end
