defmodule Spark.Dsl.MetaDsl.Transformer do
  @moduledoc """
  Transforms the meta-DSL definitions into actual Spark DSL structures.

  This transformer takes the meta-DSL configuration and generates the necessary
  Spark.Dsl.Entity and Spark.Dsl.Section structs, then injects the extension
  code into the module.
  """

  use Spark.Dsl.Transformer

  alias Spark.Dsl.MetaDsl.{MetaEntity, MetaSection}

  def transform(dsl_state) do
    with {:ok, dsl_state} <- build_entities(dsl_state),
         {:ok, dsl_state} <- build_sections(dsl_state),
         {:ok, dsl_state} <- build_extension(dsl_state) do
      {:ok, dsl_state}
    end
  end

  defp build_entities(dsl_state) do
    meta_entities = Spark.Dsl.Extension.get_entities(dsl_state, [:entities])

    entities = Enum.map(meta_entities, &meta_entity_to_spark_entity/1)

    dsl_state = Spark.Dsl.Transformer.persist(dsl_state, :built_entities, entities)

    {:ok, dsl_state}
  end

  defp build_sections(dsl_state) do
    meta_sections = Spark.Dsl.Extension.get_entities(dsl_state, [:sections])
    built_entities = Spark.Dsl.Transformer.get_persisted(dsl_state, :built_entities, [])

    sections = Enum.map(meta_sections, fn meta_section ->
      meta_section_to_spark_section(meta_section, built_entities)
    end)

    dsl_state = Spark.Dsl.Transformer.persist(dsl_state, :built_sections, sections)

    {:ok, dsl_state}
  end

  defp build_extension(dsl_state) do
    extension_configs = Spark.Dsl.Extension.get_entities(dsl_state, [:extension])
    built_sections = Spark.Dsl.Transformer.get_persisted(dsl_state, :built_sections, [])

    case extension_configs do
      [extension_config] ->
        extension_data = %{
          sections: filter_sections_by_names(built_sections, extension_config.sections),
          transformers: extension_config.transformers,
          verifiers: extension_config.verifiers,
          imports: extension_config.imports
        }

        dsl_state = Spark.Dsl.Transformer.persist(dsl_state, :extension_data, extension_data)
        {:ok, dsl_state}

      [] ->
        extension_data = %{
          sections: built_sections,
          transformers: [],
          verifiers: [],
          imports: []
        }

        dsl_state = Spark.Dsl.Transformer.persist(dsl_state, :extension_data, extension_data)
        {:ok, dsl_state}

      _ ->
        {:error, "Only one extension configuration is allowed"}
    end
  end

  defp meta_entity_to_spark_entity(%MetaEntity{} = meta_entity) do
    %Spark.Dsl.Entity{
      name: meta_entity.name,
      target: meta_entity.target,
      args: meta_entity.args,
      schema: meta_entity.schema,
      describe: meta_entity.describe,
      examples: meta_entity.examples,
      entities: resolve_nested_entities(meta_entity.entities),
      singleton_entity_keys: meta_entity.singleton_entity_keys,
      identifier: meta_entity.identifier,
      auto_set_fields: meta_entity.auto_set_fields,
      transform: meta_entity.transform,
      deprecations: meta_entity.deprecations,
      links: meta_entity.links,
      modules: meta_entity.modules,
      imports: meta_entity.imports,
      hide: meta_entity.hide,
      snippet: meta_entity.snippet,
      recursive_as: meta_entity.recursive_as
    }
  end

  defp meta_section_to_spark_section(%MetaSection{} = meta_section, built_entities) do
    section_entities = filter_entities_by_names(built_entities, meta_section.entities)

    %Spark.Dsl.Section{
      name: meta_section.name,
      entities: section_entities,
      sections: resolve_nested_sections(meta_section.sections),
      schema: meta_section.schema,
      describe: meta_section.describe,
      examples: meta_section.examples,
      top_level?: meta_section.top_level?,
      imports: meta_section.imports,
      auto_set_fields: meta_section.auto_set_fields,
      deprecations: meta_section.deprecations,
      links: meta_section.links,
      modules: meta_section.modules,
      snippet: meta_section.snippet,
      patchable?: meta_section.patchable?
    }
  end

  defp resolve_nested_entities(entity_names) when is_list(entity_names) do
    []
  end

  defp resolve_nested_sections(section_names) when is_list(section_names) do
    []
  end

  defp filter_entities_by_names(entities, names) do
    Enum.filter(entities, fn entity -> entity.name in names end)
  end

  defp filter_sections_by_names(sections, names) do
    Enum.filter(sections, fn section -> section.name in names end)
  end

  def after_compile(env) do
    dsl_state = Module.get_attribute(env.module, :spark_dsl_config)

    case Spark.Dsl.Transformer.get_persisted(dsl_state, :extension_data) do
      nil ->
        :ok

      extension_data ->
        generate_extension_module(env.module, extension_data)
    end
  end

  defp generate_extension_module(module, extension_data) do
    extension_module_name = Module.concat(module, "Generated")

    extension_ast = quote do
      defmodule unquote(extension_module_name) do
        use Spark.Dsl.Extension,
          sections: unquote(Macro.escape(extension_data.sections)),
          transformers: unquote(extension_data.transformers),
          verifiers: unquote(extension_data.verifiers),
          imports: unquote(extension_data.imports)
      end
    end

    Code.eval_quoted(extension_ast)

    Module.put_attribute(module, :generated_extension, extension_module_name)

    :ok
  end
end