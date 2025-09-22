defmodule Spark.Test.TraditionalDslExample do
  @moduledoc """
  This is what our meta-DSL would generate - a traditional Spark DSL extension.
  This demonstrates the target output that our meta-DSL aims to produce.
  """

  # Define target structs
  defmodule Car do
    defstruct [:make, :model, :year, __identifier__: nil]
  end

  # This is the traditional way to define a Spark DSL extension
  defmodule Dsl do
    @car_entity %Spark.Dsl.Entity{
      name: :car,
      target: Spark.Test.TraditionalDslExample.Car,
      args: [:make, :model],
      schema: [
        make: [type: :atom, required: true, doc: "Car manufacturer"],
        model: [type: :atom, required: true, doc: "Car model"],
        year: [type: :integer, doc: "Manufacturing year"]
      ],
      describe: "Defines a car in the fleet",
      examples: [
        "car :toyota, :camry, year: 2023"
      ]
    }

    @cars_section %Spark.Dsl.Section{
      name: :cars,
      describe: "Configure the car fleet",
      entities: [@car_entity],
      schema: [
        default_make: [type: :atom, doc: "Default manufacturer"]
      ]
    }

    use Spark.Dsl.Extension,
      sections: [@cars_section]
  end

  # Create the DSL module
  use Spark.Dsl, default_extensions: [extensions: Dsl]

  defmacro __using__(opts) do
    super(opts)
  end
end