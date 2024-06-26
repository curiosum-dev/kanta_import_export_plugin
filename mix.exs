defmodule Kanta.ImportExport.MixProject do
  use Mix.Project

  def project do
    [
      app: :kanta_import_export_plugin,
      version: "0.1.0",
      elixir: "~> 1.15",
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
      {:kanta,
       github: "curiosum-dev/kanta",
       branch: "feature/add_support_for_multiple_apps",
       override: true}
    ]
  end
end
