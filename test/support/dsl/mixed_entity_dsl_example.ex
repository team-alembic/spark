defmodule Spark.Test.MixedEntityDslExample do
  @moduledoc """
  Example DSL builder usage with mixed entity types.

  Demonstrates a configuration DSL with both:
  - Flat entities (settings)
  - Nested entities (features with options)
  """

  use Spark.DslBuilder

  # Define target structs
  defmodule Setting do
    defstruct [:key, :value, :type, __identifier__: nil]
  end

  defmodule Feature do
    defstruct [:name, :enabled, :description, options: [], __identifier__: nil]
  end

  defmodule Option do
    defstruct [:key, :value, :default, __identifier__: nil]
  end

  # Define entities using DSL Builder
  entities do
    entity :option do
      target Spark.Test.MixedEntityDslExample.Option
      args [:key]
      schema [
        key: [type: :atom, required: true, doc: "Option key"],
        value: [type: :any, doc: "Option value"],
        default: [type: :any, doc: "Default value"]
      ]
      describe "Defines a feature option"
      examples ["option :timeout, value: 5000, default: 30000"]
    end

    entity :setting do
      target Spark.Test.MixedEntityDslExample.Setting
      args [:key]
      schema [
        key: [type: :atom, required: true, doc: "Setting key"],
        value: [type: :any, required: true, doc: "Setting value"],
        type: [type: {:in, [:string, :integer, :boolean, :atom]}, default: :string, doc: "Value type"]
      ]
      describe "Defines a global setting"
      examples [
        "setting :debug_mode, value: true, type: :boolean",
        "setting :max_connections, value: 100, type: :integer"
      ]
    end

    entity :feature do
      target Spark.Test.MixedEntityDslExample.Feature
      args [:name]
      entities [:option]
      schema [
        name: [type: :atom, required: true, doc: "Feature name"],
        enabled: [type: :boolean, default: true, doc: "Whether feature is enabled"],
        description: [type: :string, doc: "Feature description"]
      ]
      describe "Defines a feature with options"
      examples [
        "feature :caching, enabled: true, description: \"Redis caching\"",
        """
        feature :rate_limiting do
          option :requests_per_minute, value: 60
          option :burst_limit, value: 10
        end
        """
      ]
    end
  end

  # Define sections
  sections do
    section :config do
      entities [:setting, :feature]
      describe "Application configuration"
      schema [
        environment: [type: {:in, [:dev, :test, :prod]}, default: :dev, doc: "Runtime environment"]
      ]
    end
  end

  # Configure extension
  extension do
    sections [:config]
  end
end
