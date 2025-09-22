defmodule Spark.Dsl.MetaDsl.Info do
  @moduledoc """
  Info module for introspecting meta-DSL configurations.

  This module provides functions to retrieve entities, sections, and extension
  configuration from modules that use the Spark.Dsl.MetaDsl extension.
  """

  use Spark.InfoGenerator,
    extension: Spark.Dsl.MetaDsl,
    sections: [:entities, :sections, :extension]

  @doc """
  Gets all entity definitions from a meta-DSL module.
  """
  def entity_definitions(module) do
    entities(module)
  end

  @doc """
  Gets all section definitions from a meta-DSL module.
  """
  def section_definitions(module) do
    sections(module)
  end

  @doc """
  Gets the extension configuration from a meta-DSL module.
  """
  def extension_config(module) do
    case extension(module) do
      [extension] -> extension
      [] -> nil
    end
  end

  @doc """
  Gets the generated extension module name for a meta-DSL module.
  """
  def generated_extension_module(module) do
    Module.get_attribute(module, :generated_extension)
  end

  @doc """
  Checks if a module uses the meta-DSL extension.
  """
  def meta_dsl_module?(module) do
    try do
      Spark.Dsl.is?(module, Spark.Dsl.MetaDsl)
    rescue
      _ -> false
    end
  end
end
