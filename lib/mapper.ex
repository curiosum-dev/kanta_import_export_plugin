defmodule Kanta.ImportExport.Mapper do
  @moduledoc """
  Mapper behaviour used for importing and exporting messages
  """

  alias Kanta.Translations.ApplicationSource
  alias Kanta.Translations.Locale

  @doc """
  Import messages:
  - used to map received data to format that can be used to create a message.
  """
  @callback import_messages(any(), ApplicationSource.t(), Locale.t()) :: any()

  @doc """
  Export messages:
  - used to map messages to desired format.
  """
  @callback export_messages(any()) :: any()

  defmacro __using__(_opts) do
    quote do
      import Kanta.ImportExport.Mapper
      alias Kanta.ImportExport.Mapper

      @behaviour Kanta.ImportExport.Mapper
    end
  end
end
