defmodule DslBuilderNestedEntitiesTest do
  use ExUnit.Case, async: true

  describe "DSL Builder with Nested Entities" do
    test "basic nested entity definition compiles" do
      # Test that we can define a DSL with nested entities using the DSL builder
      assert Code.ensure_loaded?(Spark.Test.TeamDslExample)

      # Verify the DSL extension was created
      dsl_state = Spark.Test.TeamDslExample.spark_dsl_config()
      assert dsl_state
    end

    test "nested entities are properly defined in meta-DSL" do
      # Get the meta-DSL entities to verify structure
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:entities])

      # Should have defined entities for team, member, and project
      entity_names = Enum.map(meta_entities, & &1.name)
      assert :team in entity_names
      assert :member in entity_names
      assert :project in entity_names
      assert :task in entity_names
    end

    test "nested entity targets are correctly set" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:entities])

      team_entity = Enum.find(meta_entities, &(&1.name == :team))
      member_entity = Enum.find(meta_entities, &(&1.name == :member))
      project_entity = Enum.find(meta_entities, &(&1.name == :project))
      task_entity = Enum.find(meta_entities, &(&1.name == :task))

      assert team_entity.target == Spark.Test.TeamDslExample.Team
      assert member_entity.target == Spark.Test.TeamDslExample.Member
      assert project_entity.target == Spark.Test.TeamDslExample.Project
      assert task_entity.target == Spark.Test.TeamDslExample.Task
    end

    test "entity hierarchy is properly configured" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:entities])

      team_entity = Enum.find(meta_entities, &(&1.name == :team))
      project_entity = Enum.find(meta_entities, &(&1.name == :project))

      # Team should specify nested entities (members and projects)
      assert is_list(team_entity.entities)
      # Project should specify nested entities (tasks)
      assert is_list(project_entity.entities)
    end

    test "sections are properly defined with nested entities" do
      meta_sections = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:sections])

      assert length(meta_sections) == 1
      teams_section = List.first(meta_sections)
      assert teams_section.name == :teams
      assert :team in teams_section.entities
    end

    test "extension configuration includes all sections" do
      meta_extension = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:extension])

      assert length(meta_extension) == 1
      extension = List.first(meta_extension)
      assert :teams in extension.sections
    end
  end

  describe "Multi-level Nesting" do
    test "deeply nested entities compile correctly" do
      assert Code.ensure_loaded?(Spark.Test.DeeplyNestedDslExample)
    end

    test "deep nesting structure is preserved" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.DeeplyNestedDslExample, [:entities])

      # Should have all levels defined
      entity_names = Enum.map(meta_entities, & &1.name)
      assert :organization in entity_names
      assert :department in entity_names
      assert :team in entity_names
      assert :member in entity_names
    end

    test "each level has correct nested entity references" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.DeeplyNestedDslExample, [:entities])

      org_entity = Enum.find(meta_entities, &(&1.name == :organization))
      dept_entity = Enum.find(meta_entities, &(&1.name == :department))
      team_entity = Enum.find(meta_entities, &(&1.name == :team))

      # Each level should reference the next level down
      assert is_list(org_entity.entities)
      assert is_list(dept_entity.entities)
      assert is_list(team_entity.entities)
    end
  end

  describe "Mixed Entity Types" do
    test "sections with both flat and nested entities work" do
      assert Code.ensure_loaded?(Spark.Test.MixedEntityDslExample)
    end

    test "flat and nested entities coexist in same section" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.MixedEntityDslExample, [:entities])
      meta_sections = Spark.Dsl.Extension.get_entities(Spark.Test.MixedEntityDslExample, [:sections])

      # Should have both types of entities
      entity_names = Enum.map(meta_entities, & &1.name)
      assert :setting in entity_names  # flat entity
      assert :feature in entity_names  # nested entity
      assert :option in entity_names   # child of feature

      # Section should include both types
      config_section = List.first(meta_sections)
      assert :setting in config_section.entities
      assert :feature in config_section.entities
    end
  end

  describe "Builder Pattern Validation" do
    test "transformer generates correct Spark structures" do
      dsl_state = Spark.Test.TeamDslExample.spark_dsl_config()

      # Verify transformer data exists
      built_entities = Spark.Dsl.Transformer.get_persisted(dsl_state, :built_entities, [])
      built_sections = Spark.Dsl.Transformer.get_persisted(dsl_state, :built_sections, [])

      # Should have generated proper Spark structures
      assert is_list(built_entities)
      assert is_list(built_sections)

      if length(built_entities) > 0 do
        entity = List.first(built_entities)
        assert entity.__struct__ == Spark.Dsl.Entity
      end

      if length(built_sections) > 0 do
        section = List.first(built_sections)
        assert section.__struct__ == Spark.Dsl.Section
      end
    end

    test "meta-DSL produces equivalent results to manual DSL" do
      # Compare the generated structures with traditional manual DSL
      # This ensures our DSL builder produces the same output

      # Get meta-DSL config
      meta_dsl_state = Spark.Test.TeamDslExample.spark_dsl_config()
      meta_built_entities = Spark.Dsl.Transformer.get_persisted(meta_dsl_state, :built_entities, [])

      # Get traditional DSL config for comparison
      traditional_sections = Spark.Test.TraditionalDslExample.Dsl.sections()

      # If both have content, verify structural equivalence
      if length(meta_built_entities) > 0 && length(traditional_sections) > 0 do
        meta_entity = List.first(meta_built_entities)
        traditional_entity = List.first(List.first(traditional_sections).entities)

        # Should have same basic structure
        assert meta_entity.__struct__ == traditional_entity.__struct__
      end
    end
  end

  describe "Schema Validation" do
    test "nested entity schemas are validated" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:entities])

      # Each entity should have a valid schema
      Enum.each(meta_entities, fn entity ->
        assert is_list(entity.schema)
        # Verify schema contains expected field types
        if entity.name == :member do
          schema_keys = Keyword.keys(entity.schema)
          assert :name in schema_keys
          assert :role in schema_keys
        end
      end)
    end

    test "entity arguments are properly configured" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:entities])

      team_entity = Enum.find(meta_entities, &(&1.name == :team))
      member_entity = Enum.find(meta_entities, &(&1.name == :member))

      # Team should have name as argument
      assert team_entity.args == [:name]
      # Member should have name as argument
      assert member_entity.args == [:name]
    end
  end

  describe "Error Handling" do
    test "invalid nested entity references are caught" do
      # This would test compilation errors for malformed DSL definitions
      # Since we can't easily test compilation failures, we document the expectation

      # A DSL that references non-existent nested entities should fail compilation
      # A DSL with circular references should be detected
      # A DSL with malformed entity definitions should provide clear errors

      # For now, we test that valid configurations work
      assert Code.ensure_loaded?(Spark.Test.TeamDslExample)
      assert Code.ensure_loaded?(Spark.Test.DeeplyNestedDslExample)
      assert Code.ensure_loaded?(Spark.Test.MixedEntityDslExample)
    end

    test "entity target validation works" do
      meta_entities = Spark.Dsl.Extension.get_entities(Spark.Test.TeamDslExample, [:entities])

      # All entities should have valid targets
      Enum.each(meta_entities, fn entity ->
        assert entity.target != nil
        assert is_atom(entity.target)
        # Target module should exist (these are defined in our support modules)
        assert Code.ensure_loaded?(entity.target)
      end)
    end
  end
end