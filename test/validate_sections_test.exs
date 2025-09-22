defmodule Spark.Dsl.ValidateSectionsTest do
  @moduledoc """
  Tests for the @validate_sections to function generation conversion.

  This test verifies that our change from module attributes to compile-time
  function generation works correctly.
  """
  use ExUnit.Case

  # Use an existing test module that we know works

  describe "__spark_validate_sections__/0 function generation" do
    test "generates function with validate sections data" do
      # Create a test module that uses a Spark DSL
      defmodule TestDslModule do
        @moduledoc false
        use Spark.Test.Contact

        personal_details do
          first_name "Test"
          last_name "User"
        end
      end

      # Verify the function exists
      assert function_exported?(TestDslModule, :__spark_validate_sections__, 0)

      # Call the function and verify it returns a list
      validate_sections = TestDslModule.__spark_validate_sections__()
      assert is_list(validate_sections)

      # Each item should be a tuple with {section_path, validator_module, extension}
      for item <- validate_sections do
        assert is_tuple(item)
        assert tuple_size(item) == 3

        {section_path, validator_module, extension} = item
        assert is_list(section_path) or is_atom(section_path)
        assert is_atom(validator_module)
        assert is_atom(extension)
      end
    end

    test "validates sections contain expected sections" do
      defmodule TestDslModule2 do
        @moduledoc false
        use Spark.Test.Contact

        personal_details do
          first_name "Test"
        end
      end

      validate_sections = TestDslModule2.__spark_validate_sections__()

      # Should contain sections from the Contact DSL
      section_paths = Enum.map(validate_sections, &elem(&1, 0))

      # The Contact DSL has :personal_details and :contact sections
      assert Enum.any?(section_paths, &(&1 == [:personal_details] or &1 == :personal_details))
    end

    test "function works correctly with fragment pattern" do
      # Test that our implementation works with the fragment validate_sections pattern
      defmodule TestDslModule3 do
        @moduledoc false
        use Spark.Test.Contact

        personal_details do
          first_name "Test"
        end
      end

      # Test the pattern that fragments use to access validate sections
      validate_sections =
        if function_exported?(TestDslModule3, :__spark_validate_sections__, 0) do
          TestDslModule3.__spark_validate_sections__()
        else
          []
        end

      assert is_list(validate_sections)
      assert length(validate_sections) > 0
    end

    test "replaces old module attribute approach" do
      # Verify that @validate_sections module attribute is not being used
      # by checking that our function-based approach works correctly

      defmodule TestDslModule4 do
        @moduledoc false
        use Spark.Test.Contact

        personal_details do
          first_name "Test"
        end
      end

      validate_sections = TestDslModule4.__spark_validate_sections__()
      assert length(validate_sections) > 0, "Should have validation sections from function, not empty list"
    end
  end

  describe "backward compatibility" do
    test "maintains same data structure as module attribute approach" do
      defmodule TestDslModule5 do
        @moduledoc false
        use Spark.Test.Contact

        personal_details do
          first_name "Test"
        end
      end

      validate_sections = TestDslModule5.__spark_validate_sections__()

      # Each validation section should have the same structure as before:
      # {section_path, validator_module, extension}
      for {section_path, validator_module, extension} <- validate_sections do
        # section_path should be a list or atom (e.g., [:personal_details])
        assert is_list(section_path) or is_atom(section_path)

        # validator_module should be a module that can validate options
        assert is_atom(validator_module)
        assert Code.ensure_loaded?(validator_module)

        # extension should be the extension module
        assert is_atom(extension)
        assert Code.ensure_loaded?(extension)
      end
    end
  end
end