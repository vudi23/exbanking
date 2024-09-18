defmodule ExBanking.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_banking,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ExBankingApp, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:con_cache, "~> 1.1.0"}
    ]
  end
end
