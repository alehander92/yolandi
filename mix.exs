defmodule Yolandi.Mixfile do
  use Mix.Project

  def project do
    [ app: :yolandi,
      version: "0.0.2",
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

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:bencoder, "~> 0.0.7"},
     {:wire, "~> 0.0.8"},
     {:tracker_request, "~> 0.0.4"}]
  end
end
