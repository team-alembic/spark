defmodule DslBuilderInvalidEntityReferencesTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "Invalid Entity References in Entities Section" do
    test "entity with non-existent nested entity reference fails compilation" do
      # Test that an entity referencing a non-existent entity in its entities list fails
      # The compilation will succeed but we should be able to see the verification errors

      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        try do
          defmodule TestInvalidNestedEntity do
            use Spark.DslBuilder

            defmodule Team do
              defstruct [:name, __identifier__: nil]
            end

            entities do
              entity :team do
                target TestInvalidNestedEntity.Team
                args [:name]
                entities [:non_existent_entity]  # This should fail
                schema [
                  name: [type: :atom, required: true]
                ]
              end
            end

            sections do
              section :teams do
                entities [:team]
              end
            end

            extension do
              sections [:teams]
            end
          end
        rescue
          error ->
            # If an error is raised, re-raise it so we can test it
            raise error
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Unknown entity references: [:non_existent_entity]"
    end

    test "entity with multiple invalid nested entity references fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestMultipleInvalidEntities do
          use Spark.DslBuilder

          defmodule Team do
            defstruct [:name, __identifier__: nil]
          end

          entities do
            entity :team do
              target TestMultipleInvalidEntities.Team
              args [:name]
              entities [:invalid_one, :invalid_two, :invalid_three]  # All should fail
              schema [
                name: [type: :atom, required: true]
              ]
            end
          end

          sections do
            section :teams do
              entities [:team]
            end
          end

          extension do
            sections [:teams]
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Unknown entity references: [:invalid_one, :invalid_two, :invalid_three]"
    end

    test "entity with mix of valid and invalid nested entity references fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestMixedValidInvalidEntities do
          use Spark.DslBuilder

          defmodule Team do
            defstruct [:name, __identifier__: nil]
          end

          defmodule Member do
            defstruct [:name, __identifier__: nil]
          end

          entities do
            entity :member do
              target TestMixedValidInvalidEntities.Member
              args [:name]
              schema [
                name: [type: :atom, required: true]
              ]
            end

            entity :team do
              target TestMixedValidInvalidEntities.Team
              args [:name]
              entities [:member, :invalid_entity]  # One valid, one invalid
              schema [
                name: [type: :atom, required: true]
              ]
            end
          end

          sections do
            section :teams do
              entities [:team]
            end
          end

          extension do
            sections [:teams]
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Unknown entity references: [:invalid_entity]"
    end

    test "entity with circular reference fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestCircularReference do
          use Spark.DslBuilder

          defmodule Team do
            defstruct [:name, __identifier__: nil]
          end

          defmodule Member do
            defstruct [:name, __identifier__: nil]
          end

          entities do
            entity :member do
              target TestCircularReference.Member
              args [:name]
              entities [:team]  # Member references team
              schema [
                name: [type: :atom, required: true]
              ]
            end

            entity :team do
              target TestCircularReference.Team
              args [:name]
              entities [:member]  # Team references member - creates circle
              schema [
                name: [type: :atom, required: true]
              ]
            end
          end

          sections do
            section :teams do
              entities [:team]
            end
          end

          extension do
            sections [:teams]
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Circular entity reference detected"
    end

    test "entity with self-reference fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestSelfReference do
          use Spark.DslBuilder

          defmodule Team do
            defstruct [:name, __identifier__: nil]
          end

          entities do
            entity :team do
              target TestSelfReference.Team
              args [:name]
              entities [:team]  # Self-reference should fail
              schema [
                name: [type: :atom, required: true]
              ]
            end
          end

          sections do
            section :teams do
              entities [:team]
            end
          end

          extension do
            sections [:teams]
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Entity cannot reference itself: :team"
    end

    test "valid nested entity references compile successfully" do
      # Positive test case to ensure our validation doesn't break valid configurations
      defmodule TestValidReferences do
        use Spark.DslBuilder

        defmodule Team do
          defstruct [:name, __identifier__: nil]
        end

        defmodule Member do
          defstruct [:name, __identifier__: nil]
        end

        defmodule Project do
          defstruct [:name, __identifier__: nil]
        end

        entities do
          entity :member do
            target TestValidReferences.Member
            args [:name]
            schema [
              name: [type: :atom, required: true]
            ]
          end

          entity :project do
            target TestValidReferences.Project
            args [:name]
            schema [
              name: [type: :atom, required: true]
            ]
          end

          entity :team do
            target TestValidReferences.Team
            args [:name]
            entities [:member, :project]  # Both valid references
            schema [
              name: [type: :atom, required: true]
            ]
          end
        end

        sections do
          section :teams do
            entities [:team]
          end
        end

        extension do
          sections [:teams]
        end
      end

      # Should compile without errors
      assert Code.ensure_loaded?(TestValidReferences)
    end
  end

  describe "Invalid Entity References in Sections" do
    test "section with non-existent entity reference fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestInvalidSectionEntity do
          use Spark.DslBuilder

          defmodule Team do
            defstruct [:name, __identifier__: nil]
          end

          entities do
            entity :team do
              target TestInvalidSectionEntity.Team
              args [:name]
              schema [
                name: [type: :atom, required: true]
              ]
            end
          end

          sections do
            section :teams do
              entities [:team, :non_existent_entity]  # Second entity doesn't exist
            end
          end

          extension do
            sections [:teams]
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Unknown entity references: [:non_existent_entity]"
    end

    test "section with all invalid entity references fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestAllInvalidSectionEntities do
          use Spark.DslBuilder

          entities do
            # No entities defined
          end

          sections do
            section :teams do
              entities [:team, :member, :project]  # All invalid
            end
          end

          extension do
            sections [:teams]
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Unknown entity references: [:team, :member, :project]"
    end
  end

  describe "Invalid Section References in Extension" do
    test "extension with non-existent section reference fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestInvalidExtensionSection do
          use Spark.DslBuilder

          defmodule Team do
            defstruct [:name, __identifier__: nil]
          end

          entities do
            entity :team do
              target TestInvalidExtensionSection.Team
              args [:name]
              schema [
                name: [type: :atom, required: true]
              ]
            end
          end

          sections do
            section :teams do
              entities [:team]
            end
          end

          extension do
            sections [:teams, :non_existent_section]  # Second section doesn't exist
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Unknown section references: [:non_existent_section]"
    end

    test "extension with all invalid section references fails compilation" do
      # Capture compilation output to verify the error message appears
      output = capture_io(:stderr, fn ->
        defmodule TestAllInvalidExtensionSections do
          use Spark.DslBuilder

          sections do
            # No sections defined
          end

          extension do
            sections [:teams, :members, :projects]  # All invalid
          end
        end
      end)

      # Verify the error message appears in the output
      assert output =~ "Unknown section references: [:teams, :members, :projects]"
    end
  end
end