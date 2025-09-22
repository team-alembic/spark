defmodule Spark.Dsl.MetaDsl.MetaExtension do
  @moduledoc """
  Represents a DSL extension definition in the meta-DSL.

  This struct captures all the information needed to generate a Spark DSL extension.
  """

  defstruct [
    :name,
    sections: [],
    transformers: [],
    verifiers: [],
    imports: [],
    __identifier__: nil
  ]
end