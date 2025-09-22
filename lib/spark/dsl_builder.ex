defmodule Spark.DslBuilder do
  @moduledoc """
  A DSL for defining Spark DSL extensions.

  This module provides a complete DSL interface that allows you to define
  Spark DSL extensions using a declarative syntax.

  ## Usage

      defmodule MyApp.CarExtension do
        use Spark.DslBuilder

        entities do
          entity :car do
            target MyApp.Car
            args [:make, :model]
            schema [
              make: [type: :atom, required: true],
              model: [type: :atom, required: true]
            ]
          end
        end

        sections do
          section :cars do
            entities [:car]
            describe "Configure cars in the fleet"
          end
        end

        extension do
          sections [:cars]
        end
      end

  This generates the equivalent manual Spark extension code automatically.
  """

  use Spark.Dsl, default_extensions: [extensions: [Spark.Dsl.MetaDsl]]

  defmacro __using__(opts) do
    super(opts)
  end
end
