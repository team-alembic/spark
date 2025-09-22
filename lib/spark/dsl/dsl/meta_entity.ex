defmodule Spark.Dsl.MetaDsl.MetaEntity do
  @moduledoc """
  Represents a DSL entity definition in the meta-DSL.

  This struct captures all the information needed to generate a `Spark.Dsl.Entity`.
  """

  defstruct [
    :name,
    :target,
    :transform,
    :recursive_as,
    examples: [],
    entities: [],
    singleton_entity_keys: [],
    deprecations: [],
    describe: "",
    snippet: "",
    args: [],
    links: nil,
    hide: [],
    identifier: nil,
    modules: [],
    imports: [],
    no_depend_modules: [],
    schema: [],
    auto_set_fields: [],
    __identifier__: nil
  ]
end