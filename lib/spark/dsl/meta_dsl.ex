defmodule Spark.Dsl.MetaDsl do
  @moduledoc """
  A DSL for defining Spark DSL extensions.

  This meta-DSL allows you to define Spark DSL extensions using a declarative syntax
  instead of manually creating `%Spark.Dsl.Entity{}` and `%Spark.Dsl.Section{}` structs.

  ## Example

      defmodule MyApp.CarExtension do
        use Spark.Dsl.MetaDsl

        entities do
          entity :car do
            target MyApp.Car
            args [:make, :model]
            schema [
              make: [type: :atom, required: true],
              model: [type: :atom, required: true],
              trim: [type: :atom, default: :sedan]
            ]
            describe "Adds a car to the fleet"
            examples ["car :ford, :focus, trim: :hatchback"]
          end
        end

        sections do
          section :cars do
            entities [:car]
            schema [
              default_manufacturer: [type: :atom, doc: "Default car manufacturer"]
            ]
            describe "Configure available cars"
          end
        end

        extension do
          sections [:cars]
          transformers [MyApp.Transformers.ValidateCars]
        end
      end

  This generates the equivalent manual Spark extension code automatically.
  """


  @entity_entity %Spark.Dsl.Entity{
    name: :entity,
    target: Spark.Dsl.MetaDsl.MetaEntity,
    args: [:name],
    describe: "Defines a DSL entity",
    examples: [
      """
      entity :my_entity do
        target MyApp.MyEntity
        args [:name]
        schema [
          name: [type: :atom, required: true]
        ]
      end
      """
    ],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the DSL entity"
      ],
      target: [
        type: :atom,
        required: true,
        doc: "The target struct module for this entity"
      ],
      args: [
        type: {:list, :atom},
        default: [],
        doc: "Positional arguments for the entity"
      ],
      schema: [
        type: :any,
        default: [],
        doc: "Schema definition using Spark.Options format"
      ],
      describe: [
        type: :string,
        default: "",
        doc: "Description of the entity"
      ],
      examples: [
        type: {:list, :string},
        default: [],
        doc: "Usage examples for the entity"
      ],
      entities: [
        type: {:list, :atom},
        default: [],
        doc: "Nested entities"
      ],
      singleton_entity_keys: [
        type: {:list, :atom},
        default: [],
        doc: "Entity keys that should have only a single value"
      ],
      identifier: [
        type: :any,
        doc: "Field to use as identifier for this entity"
      ],
      auto_set_fields: [
        type: :any,
        default: [],
        doc: "Fields to automatically set on the entity"
      ],
      transform: [
        type: :any,
        doc: "Transform function to apply to the entity"
      ],
      deprecations: [
        type: :any,
        default: [],
        doc: "Deprecation warnings for fields"
      ],
      links: [
        type: :any,
        doc: "Documentation links"
      ],
      modules: [
        type: {:list, :atom},
        default: [],
        doc: "Modules to depend on"
      ],
      imports: [
        type: {:list, :atom},
        default: [],
        doc: "Modules to import"
      ],
      hide: [
        type: {:list, :atom},
        default: [],
        doc: "Fields to hide from documentation"
      ],
      snippet: [
        type: :string,
        default: "",
        doc: "Code snippet for the entity"
      ],
      recursive_as: [
        type: :atom,
        doc: "Allow recursive definition as this name"
      ]
    ]
  }

  @section_entity %Spark.Dsl.Entity{
    name: :section,
    target: Spark.Dsl.MetaDsl.MetaSection,
    args: [:name],
    describe: "Defines a DSL section",
    examples: [
      """
      section :my_section do
        entities [:my_entity]
        schema [
          option: [type: :string, doc: "A section option"]
        ]
        describe "My custom section"
      end
      """
    ],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the DSL section"
      ],
      entities: [
        type: {:list, :atom},
        default: [],
        doc: "List of entity names in this section"
      ],
      sections: [
        type: {:list, :atom},
        default: [],
        doc: "List of nested section names"
      ],
      schema: [
        type: :any,
        default: [],
        doc: "Schema definition for section options"
      ],
      describe: [
        type: :string,
        default: "",
        doc: "Description of the section"
      ],
      examples: [
        type: {:list, :string},
        default: [],
        doc: "Usage examples for the section"
      ],
      top_level?: [
        type: :boolean,
        default: false,
        doc: "Whether this section can be declared at the top level"
      ],
      imports: [
        type: {:list, :atom},
        default: [],
        doc: "Modules to import in this section"
      ],
      auto_set_fields: [
        type: :any,
        default: [],
        doc: "Fields to automatically set on the section"
      ],
      deprecations: [
        type: :any,
        default: [],
        doc: "Deprecation warnings for fields"
      ],
      links: [
        type: :any,
        doc: "Documentation links"
      ],
      modules: [
        type: {:list, :atom},
        default: [],
        doc: "Modules to depend on"
      ],
      snippet: [
        type: :string,
        default: "",
        doc: "Code snippet for the section"
      ],
      patchable?: [
        type: :boolean,
        default: false,
        doc: "Whether this section can be patched"
      ]
    ]
  }

  @extension_entity %Spark.Dsl.Entity{
    name: :extension,
    target: Spark.Dsl.MetaDsl.MetaExtension,
    describe: "Defines the DSL extension configuration",
    examples: [
      """
      extension do
        sections [:my_section]
        transformers [MyApp.MyTransformer]
        verifiers [MyApp.MyVerifier]
      end
      """
    ],
    schema: [
      sections: [
        type: {:list, :atom},
        default: [],
        doc: "List of section names to include in this extension"
      ],
      transformers: [
        type: {:list, :atom},
        default: [],
        doc: "List of transformer modules"
      ],
      verifiers: [
        type: {:list, :atom},
        default: [],
        doc: "List of verifier modules"
      ],
      imports: [
        type: {:list, :atom},
        default: [],
        doc: "Modules to import globally"
      ]
    ]
  }

  @entities_section %Spark.Dsl.Section{
    name: :entities,
    describe: "Define DSL entities for your extension",
    entities: [@entity_entity]
  }

  @sections_section %Spark.Dsl.Section{
    name: :sections,
    describe: "Define DSL sections for your extension",
    entities: [@section_entity]
  }

  @extension_section %Spark.Dsl.Section{
    name: :extension,
    top_level?: true,
    describe: "Configure the DSL extension",
    entities: [@extension_entity]
  }

  use Spark.Dsl.Extension,
    sections: [@entities_section, @sections_section, @extension_section],
    transformers: [Spark.Dsl.MetaDsl.Transformer],
    verifiers: [Spark.Dsl.MetaDsl.Verifier]
end
