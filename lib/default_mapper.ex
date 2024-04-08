defmodule Kanta.ImportExport.DefaultMapper do
  @moduledoc """
  Default mapper.

  Export:
  - no changes to the messages

  Import:
  - updates the messages with the context, domain and application source
  - updates the singular and plural translations with the locale
  - creates the context and domain if provided do not exist
  - input format examples:
    %{
      "msgid": "Test Message",
      "message_type": "singular",
      "domain": "some domain",
      "context": "some context",
      "singular_translations" => [
        %{
          "original_text" => "Test Message",
          "translated_text" => "Test Message",
        }
      ]
    }

    %{
      "msgid": "Test Messages",
      "message_type": "plural",
      "plural_translations" => [
        %{
          "original_text" => "Test Message",
          "translated_text" => "Test Message",
          "nplural_index" => 0
        }
      ]
    }
  """

  use Kanta.ImportExport.Mapper

  alias Kanta.Translations

  @impl Mapper
  def export_messages(messages), do: messages

  @impl Mapper
  def import_messages(messages, application_source, locale) do
    domains = Translations.list_all_domains()
    contexts = Translations.list_all_contexts()

    messages
    |> Enum.map(fn message ->
      message
      |> Map.put("application_source_id", application_source.id)
      |> update_message_with_context(contexts)
      |> update_message_with_domain(domains)
      |> Map.update("singular_translations", [], fn singular_translations ->
        Enum.map(singular_translations, &Map.put(&1, "locale_id", locale.id))
      end)
      |> Map.update("plural_translations", [], fn plural_translations ->
        Enum.map(plural_translations, &Map.put(&1, "locale_id", locale.id))
      end)
    end)
  end

  defp update_message_with_context(message, contexts) do
    context_name = Map.get(message, "context")
    context_id = find_context_id(contexts, context_name)
    context_id = maybe_create_context(context_id, context_name)

    message
    |> Map.delete("context")
    |> Map.put("context_id", context_id)
  end

  defp update_message_with_domain(message, domains) do
    domain_name = Map.get(message, "domain")
    domain_id = find_domain_id(domains, domain_name)
    domain_id = maybe_create_domain(domain_id, domain_name)

    message
    |> Map.delete("domain")
    |> Map.put("domain_id", domain_id)
  end

  defp find_context_id(_contexts, nil), do: nil

  defp find_context_id(contexts, context_name) do
    Enum.find_value(contexts, fn context -> if context.name == context_name, do: context.id end)
  end

  defp find_domain_id(_domains, nil), do: nil

  defp find_domain_id(domains, domain_name) do
    Enum.find_value(domains, fn domain -> if domain.name == domain_name, do: domain.id end)
  end

  defp maybe_create_context(nil, context_name) do
    %{name: context_name}
    |> Translations.create_context()
    |> then(fn
      {:ok, context} -> context.id
      {:error, _} -> nil
    end)
  end

  defp maybe_create_context(context_id, _context_name), do: context_id

  defp maybe_create_domain(nil, domain_name) do
    %{name: domain_name}
    |> Translations.create_domain()
    |> then(fn
      {:ok, domain} -> domain.id
      {:error, _} -> nil
    end)
  end

  defp maybe_create_domain(domain_id, _domain_name), do: domain_id
end
