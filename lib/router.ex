defmodule Kanta.ImportExport.Router do
  @moduledoc false

  alias Kanta.ImportExport.DefaultMapper
  alias Kanta.ImportExport.MapperPlug

  defmacro kanta_import_export(path \\ "/kanta-ie", mapper \\ DefaultMapper) do
    quote bind_quoted: binding() do
      pipeline :kanta_ie_pipeline do
        plug :accepts, ["json"]
        plug KantaWeb.APIAuthPlug
        plug MapperPlug, mapper: mapper
      end

      scope path, alias: false, as: false do
        pipe_through :kanta_ie_pipeline
        get "/:app/:locale", Kanta.ImportExport.ExportController, :index
        post "/:app/:locale", Kanta.ImportExport.ImportController, :index
      end
    end
  end
end
