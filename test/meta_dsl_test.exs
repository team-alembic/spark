defmodule MetaDslTest do
  use ExUnit.Case, async: true

  test "meta-DSL extension is properly defined" do
    # Test that our meta-DSL extension is properly configured
    assert Code.ensure_loaded?(Spark.Dsl.MetaDsl)

    # Verify the extension has the expected sections
    sections = Spark.Dsl.MetaDsl.sections()
    section_names = Enum.map(sections, & &1.name)

    assert :entities in section_names
    assert :sections in section_names
    assert :extension in section_names
  end

  test "meta-DSL entities are correctly defined" do
    # Find the entities section
    entities_section = Enum.find(Spark.Dsl.MetaDsl.sections(), &(&1.name == :entities))
    assert entities_section

    # Should have an entity entity
    entity_entity = Enum.find(entities_section.entities, &(&1.name == :entity))
    assert entity_entity
    assert entity_entity.target == Spark.Dsl.MetaDsl.MetaEntity
  end

  test "meta-DSL sections are correctly defined" do
    # Find the sections section
    sections_section = Enum.find(Spark.Dsl.MetaDsl.sections(), &(&1.name == :sections))
    assert sections_section

    # Should have a section entity
    section_entity = Enum.find(sections_section.entities, &(&1.name == :section))
    assert section_entity
    assert section_entity.target == Spark.Dsl.MetaDsl.MetaSection
  end

  test "meta-DSL extension section is correctly defined" do
    # Find the extension section
    extension_section = Enum.find(Spark.Dsl.MetaDsl.sections(), &(&1.name == :extension))
    assert extension_section
    assert extension_section.top_level? == true

    # Should have an extension entity
    extension_entity = Enum.find(extension_section.entities, &(&1.name == :extension))
    assert extension_entity
    assert extension_entity.target == Spark.Dsl.MetaDsl.MetaExtension
  end
end
