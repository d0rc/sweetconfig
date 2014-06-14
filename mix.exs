defmodule Sweetconfig.Mixfile do
  use Mix.Project

  def project do
    [app: :sweetconfig,
     version: "0.0.1",
     elixir: "~> 0.14.1-dev",
     deps: deps]
  end

  def application do
    [applications: [:yamler],
     mod: {Sweetconfig, []}]
  end

  defp deps do
    [
      {:yamler, github: "goertzenator/yamler", branch: "mapping_as_map"}
    ]
  end
end
