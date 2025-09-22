defmodule Spark.Dsl.MetaDsl.MetaSection do
  @moduledoc """
  Represents a DSL section definition in the meta-DSL.

  This struct captures all the information needed to generate a `Spark.Dsl.Section`.
  """

  defstruct [
    :name,
    imports: [],
    schema: [],
    describe: "",
    snippet: "",
    links: nil,
    after_define: nil,
    examples: [],
    modules: [],
    top_level?: false,
    no_depend_modules: [],
    auto_set_fields: [],
    deprecations: [],
    entities: [],
    sections: [],
    patchable?: false,
    __identifier__: nil
  ]
end