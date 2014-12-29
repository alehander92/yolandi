defmodule Yolandi.Mixfile do
  use Mix.Project

  def project do
    [ app: :yolandi,
      version: "0.0.1",
      elixir: "~> 1.0.0",
      package: package,
      description: "a mini console torrent client in elixir",
      deps: deps,
      escript: [
          main_module: Yolandi]]
  end

  defp package do
    [ licenses: ["MIT"],
      links: %{"Github" => "https://github.com/alehander42/yolandi"}]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:bencoder, "~> 0.0.7"}]
  end
end
