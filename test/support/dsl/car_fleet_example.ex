defmodule Spark.Test.CarFleetExample do
  @moduledoc """
  Example module that uses the traditional DSL to define a car fleet.
  This demonstrates how the generated DSL would be used.
  """

  use Spark.Test.TraditionalDslExample

  cars do
    car :toyota, :camry, year: 2023
    car :honda, :civic, year: 2022
    car :ford, :focus
  end
end