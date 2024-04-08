defmodule Kanta.ImportExport.ExportController do
  @moduledoc false
  use KantaWeb, :controller

  alias Kanta.Translations
  alias Kanta.Translations.SingularTranslations.Finders.ListSingularTranslations
  alias Kanta.Translations.PluralTranslations.Finders.ListPluralTranslations

  @available_params ~w(domain context)s

  def index(conn, %{"app" => application_source_name, "locale" => locale_code} = params) do
    application_source = get_application_source(application_source_name)
    locale = get_locale(locale_code)
    params = parse_params(params)
    mapper = conn.assigns.mapper

    case list_messages(application_source, locale, params) do
      {:error, error} ->
        conn
        |> put_status(404)
        |> json(%{status: error})

      messages ->
        conn
        |> put_status(200)
        |> json(mapper.export_messages(messages))
    end
  end

  defp list_messages({:error, error}, _locale, _params) do
    {:error, error}
  end

  defp list_messages(_application_source, {:error, error}, _params) do
    {:error, error}
  end

  defp list_messages(application_source, locale, params) do
    filters =
      Map.merge(params, %{
        "application_source_id" => application_source.id,
        "locale_id" => locale.id
      })

    preload_filters = Map.take(filters, ["locale_id"])
    singular_translation_query = ListSingularTranslations.filter_query(preload_filters)
    plural_translation_query = ListPluralTranslations.filter_query(preload_filters)

    preloads = [
      :context,
      :domain,
      singular_translations: singular_translation_query,
      plural_translations: plural_translation_query
    ]

    Translations.list_all_messages(filter: filters, preloads: preloads)
  end

  defp parse_params(params) do
    params
    |> Map.take(@available_params)
    |> Enum.map(fn
      {"domain", domain_name} ->
        {"domain_id", get_domain_id(domain_name)}

      {"context", context_name} ->
        {"context_id", get_context_id(context_name)}

      other ->
        other
    end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp get_application_source(application_source_name) do
    case Translations.get_application_source(filter: [name: application_source_name]) do
      {:error, _, _} -> {:error, "Application not found"}
      {:ok, application_source} -> application_source
    end
  end

  defp get_locale(locale_code) do
    case Translations.get_locale(filter: [iso639_code: locale_code]) do
      {:error, _, _} -> {:error, "Locale not found"}
      {:ok, locale} -> locale
    end
  end

  defp get_domain_id(domain_name) do
    case Translations.get_domain(filter: [name: domain_name]) do
      {:error, _, _} -> nil
      {:ok, domain} -> domain.id
    end
  end

  defp get_context_id(context_name) do
    case Translations.get_context(filter: [name: context_name]) do
      {:error, _, _} -> nil
      {:ok, context} -> context.id
    end
  end
end
