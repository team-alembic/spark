defmodule Spark.Test.MetaCarDslExample do
  @moduledoc """
  This demonstrates using our meta-DSL to define the same car DSL
  as the traditional example. This should generate equivalent functionality
  to Spark.Test.TraditionalDslExample.

  IMPORTANT: This file demonstrates the intended usage but may not compile
  due to known compilation issues with @validate_sections. The structure
  shows what our meta-DSL should support.
  """

  use Spark.DslBuilder

  # Define the target struct (same as traditional example)
  defmodule Car do
    defstruct [:make, :model, :year, __identifier__: nil]
  end

  # Define entities using meta-DSL (equivalent to @car_entity in traditional example)
  entities do
    entity :car do
      target Spark.Test.MetaCarDslExample.Car
      args [:make, :model]
      schema [
        make: [type: :atom, required: true, doc: "Car manufacturer"],
        model: [type: :atom, required: true, doc: "Car model"],
        year: [type: :integer, doc: "Manufacturing year"]
      ]
      describe "Defines a car in the fleet"
      examples ["car :toyota, :camry, year: 2023"]
    end
  end

  # Define sections using meta-DSL (equivalent to @cars_section in traditional example)
  sections do
    section :cars do
      entities [:car]
      describe "Configure the car fleet"
      schema [
        default_make: [type: :atom, doc: "Default manufacturer"]
      ]
    end
  end

  # Configure extension (equivalent to use Spark.Dsl.Extension in traditional example)
  extension do
    sections [:cars]
  end
end
