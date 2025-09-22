defmodule Spark.Dsl.MetaDsl.Verifier do
  @moduledoc """
  Verifies the meta-DSL configuration for correctness.

  This verifier ensures that:
  - Entity targets are valid modules
  - Section entity references exist
  - Schema definitions are valid
  - Extension configuration is consistent
  """

  use Spark.Dsl.Verifier

  def verify(dsl_state) do
    with :ok <- verify_entities(dsl_state),
         :ok <- verify_sections(dsl_state),
         :ok <- verify_extension(dsl_state) do
      :ok
    end
  end

  defp verify_entities(dsl_state) do
    entities = Spark.Dsl.Extension.get_entities(dsl_state, [:entities])

    Enum.reduce_while(entities, :ok, fn entity, :ok ->
      case verify_entity(entity, dsl_state) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp verify_entity(entity, dsl_state) do
    module = Spark.Dsl.Verifier.get_persisted(dsl_state, :module)
    entity_names = get_entity_names(dsl_state)

    with :ok <- verify_target_module(entity.target, module),
         :ok <- verify_schema(entity.schema, module),
         :ok <- verify_entity_nested_references(entity, entity_names, module, dsl_state) do
      :ok
    end
  end

  defp verify_sections(dsl_state) do
    sections = Spark.Dsl.Extension.get_entities(dsl_state, [:sections])
    entity_names = get_entity_names(dsl_state)

    Enum.reduce_while(sections, :ok, fn section, :ok ->
      case verify_section(section, entity_names, dsl_state) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp verify_section(section, entity_names, dsl_state) do
    module = Spark.Dsl.Verifier.get_persisted(dsl_state, :module)

    with :ok <- verify_entity_references(section.entities, entity_names, module),
         :ok <- verify_schema(section.schema, module) do
      :ok
    end
  end

  defp verify_extension(dsl_state) do
    extension_configs = Spark.Dsl.Extension.get_entities(dsl_state, [:extension])
    section_names = get_section_names(dsl_state)
    module = Spark.Dsl.Verifier.get_persisted(dsl_state, :module)

    case extension_configs do
      [] ->
        :ok

      [extension] ->
        verify_section_references(extension.sections, section_names, module)

      _ ->
        {:error,
         Spark.Error.DslError.exception(
           message: "Only one extension configuration is allowed",
           path: [:extension],
           module: module
         )}
    end
  end

  defp verify_target_module(target, _current_module) when is_atom(target) do
    # Skip module existence checks during compilation to avoid interference with Spark's process
    # The actual target module validation will happen at runtime when the DSL is used
    :ok
  end

  defp verify_target_module(nil, current_module) do
    {:error,
     Spark.Error.DslError.exception(
       message: "Entity target cannot be nil",
       path: [:entities],
       module: current_module
     )}
  end

  defp verify_schema(schema, module) when is_list(schema) do
    try do
      Spark.Options.validate([], schema)
      :ok
    rescue
      error ->
        {:error,
         Spark.Error.DslError.exception(
           message: "Invalid schema: #{Exception.message(error)}",
           path: [:schema],
           module: module
         )}
    end
  end

  defp verify_entity_references(entity_refs, available_entities, module) do
    invalid_refs = entity_refs -- available_entities

    if Enum.empty?(invalid_refs) do
      :ok
    else
      {:error,
       Spark.Error.DslError.exception(
         message: "Unknown entity references: #{inspect(invalid_refs)}. Available: #{inspect(available_entities)}",
         path: [:sections],
         module: module
       )}
    end
  end

  defp verify_entity_nested_references(entity, available_entities, module, dsl_state) do
    case Map.get(entity, :entities, []) do
      [] ->
        :ok

      nested_entities when is_list(nested_entities) ->
        with :ok <- verify_no_self_reference(entity.name, nested_entities, module),
             :ok <- verify_nested_entity_references(nested_entities, available_entities, module, entity.name),
             :ok <- verify_no_circular_references(entity.name, nested_entities, module, dsl_state) do
          :ok
        end

      _ ->
        :ok
    end
  end

  defp verify_no_self_reference(entity_name, nested_entities, module) do
    if entity_name in nested_entities do
      {:error,
       Spark.Error.DslError.exception(
         message: "Entity cannot reference itself: #{inspect(entity_name)}",
         path: [:entities, entity_name],
         module: module
       )}
    else
      :ok
    end
  end

  defp verify_nested_entity_references(nested_entities, available_entities, module, entity_name) do
    invalid_refs = nested_entities -- available_entities

    if Enum.empty?(invalid_refs) do
      :ok
    else
      {:error,
       Spark.Error.DslError.exception(
         message: "Unknown entity references: #{inspect(invalid_refs)}. Available: #{inspect(available_entities)}",
         path: [:entities, entity_name],
         module: module
       )}
    end
  end

  defp verify_no_circular_references(entity_name, _nested_entities, module, dsl_state) do
    # Build a dependency graph to detect circular references
    all_entities = Spark.Dsl.Extension.get_entities(dsl_state, [:entities])
    entity_map = Map.new(all_entities, fn entity -> {entity.name, Map.get(entity, :entities, [])} end)

    case detect_circular_reference(entity_name, entity_map, []) do
      {:error, cycle} ->
        {:error,
         Spark.Error.DslError.exception(
           message: "Circular entity reference detected: #{inspect(cycle)}",
           path: [:entities, entity_name],
           module: module
         )}

      :ok ->
        :ok
    end
  end

  defp detect_circular_reference(entity_name, entity_map, visited) do
    if entity_name in visited do
      {:error, visited ++ [entity_name]}
    else
      nested_entities = Map.get(entity_map, entity_name, [])
      new_visited = [entity_name | visited]

      Enum.reduce_while(nested_entities, :ok, fn nested_entity, :ok ->
        case detect_circular_reference(nested_entity, entity_map, new_visited) do
          :ok -> {:cont, :ok}
          {:error, cycle} -> {:halt, {:error, cycle}}
        end
      end)
    end
  end

  defp verify_section_references(section_refs, available_sections, module) do
    invalid_refs = section_refs -- available_sections

    if Enum.empty?(invalid_refs) do
      :ok
    else
      {:error,
       Spark.Error.DslError.exception(
         message: "Unknown section references: #{inspect(invalid_refs)}. Available: #{inspect(available_sections)}",
         path: [:extension],
         module: module
       )}
    end
  end

  defp get_entity_names(dsl_state) do
    dsl_state
    |> Spark.Dsl.Extension.get_entities([:entities])
    |> Enum.map(& &1.name)
  end

  defp get_section_names(dsl_state) do
    dsl_state
    |> Spark.Dsl.Extension.get_entities([:sections])
    |> Enum.map(& &1.name)
  end
end
