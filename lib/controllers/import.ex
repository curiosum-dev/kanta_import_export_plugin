defmodule Kanta.ImportExport.ImportController do
  @moduledoc false
  use KantaWeb, :controller

  alias Kanta.Translations

  @message_conflict [:msgid, :application_source_id, :context_id, :domain_id]
  @singular_translation_conflict [:message_id, :locale_id]
  @plural_translation_conflict [:message_id, :locale_id, :nplural_index]

  def index(conn, %{
        "messages" => messages,
        "app" => application_source_name,
        "locale" => locale_code
      }) do
    application_source = get_application_source(application_source_name)
    locale = get_locale(locale_code)

    if is_nil(application_source) or is_nil(locale) do
      conn
      |> put_status(404)
      |> json(%{status: "Not Found"})
    else
      mapper = conn.assigns.mapper
      mapped_messages = mapper.import_messages(messages, application_source, locale)
      save_messages(mapped_messages)

      conn
      |> put_status(200)
      |> json(%{status: "OK"})
    end
  end

  defp save_messages(mapped_messages) do
    Enum.each(mapped_messages, fn mapped_message ->
      singular_translations = Map.get(mapped_message, "singular_translations", [])
      plural_translations = Map.get(mapped_message, "plural_translations", [])
      message_attrs = Map.drop(mapped_message, ["singular_translations", "plural_translations"])

      {:ok, message} =
        Translations.create_message(message_attrs,
          on_conflict: {:replace_all_except, [:id, :inserted_at]},
          conflict_target: @message_conflict
        )

      Enum.each(singular_translations, fn translation ->
        translation = Map.put(translation, "message_id", message.id)

        {:ok, _} =
          Translations.create_singular_translation(translation,
            on_conflict: {:replace_all_except, [:id, :inserted_at]},
            conflict_target: @singular_translation_conflict
          )
      end)

      Enum.each(plural_translations, fn translation ->
        translation = Map.put(translation, "message_id", message.id)

        {:ok, _} =
          Translations.create_plural_translation(translation,
            on_conflict: {:replace_all_except, [:id, :inserted_at]},
            conflict_target: @plural_translation_conflict
          )
      end)
    end)
  end

  defp get_application_source(application_source_name) do
    case Translations.get_application_source(filter: [name: application_source_name]) do
      {:error, _, _} -> nil
      {:ok, application_source} -> application_source
    end
  end

  defp get_locale(locale_code) do
    case Translations.get_locale(filter: [iso639_code: locale_code]) do
      {:error, _, _} -> nil
      {:ok, locale} -> locale
    end
  end
end
