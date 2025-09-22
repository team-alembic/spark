defmodule Spark.Test.DeeplyNestedDslExample do
  @moduledoc """
  Example DSL builder usage with deep nesting (4 levels).

  Demonstrates:
  - Organization > Department > Team > Member
  """

  use Spark.DslBuilder

  # Define target structs
  defmodule Organization do
    defstruct [:name, :type, departments: [], __identifier__: nil]
  end

  defmodule Department do
    defstruct [:name, :budget, teams: [], __identifier__: nil]
  end

  defmodule Team do
    defstruct [:name, :focus, members: [], __identifier__: nil]
  end

  defmodule Member do
    defstruct [:name, :position, :level, __identifier__: nil]
  end

  # Define entities using DSL Builder with deep nesting
  entities do
    entity :member do
      target Spark.Test.DeeplyNestedDslExample.Member
      args [:name]
      schema [
        name: [type: :atom, required: true, doc: "Member name"],
        position: [type: :string, required: true, doc: "Job position"],
        level: [type: {:in, [:junior, :mid, :senior, :lead]}, default: :junior, doc: "Experience level"]
      ]
      describe "Defines an organization member"
      examples ["member :alice, position: \"Software Engineer\", level: :senior"]
    end

    entity :team do
      target Spark.Test.DeeplyNestedDslExample.Team
      args [:name]
      entities [:member]
      schema [
        name: [type: :atom, required: true, doc: "Team name"],
        focus: [type: :string, doc: "Team focus area"]
      ]
      describe "Defines a team with members"
      examples [
        "team :backend, focus: \"API Development\"",
        """
        team :frontend do
          member :bob, position: "UI Developer"
          member :carol, position: "UX Designer"
        end
        """
      ]
    end

    entity :department do
      target Spark.Test.DeeplyNestedDslExample.Department
      args [:name]
      entities [:team]
      schema [
        name: [type: :atom, required: true, doc: "Department name"],
        budget: [type: :integer, doc: "Department budget"]
      ]
      describe "Defines a department with teams"
      examples [
        "department :engineering, budget: 1000000",
        """
        department :product do
          team :design do
            member :eve, position: "Product Designer"
          end

          team :research do
            member :frank, position: "User Researcher"
          end
        end
        """
      ]
    end

    entity :organization do
      target Spark.Test.DeeplyNestedDslExample.Organization
      args [:name]
      entities [:department]
      schema [
        name: [type: :atom, required: true, doc: "Organization name"],
        type: [type: {:in, [:startup, :enterprise, :nonprofit]}, default: :startup, doc: "Organization type"]
      ]
      describe "Defines an organization with departments"
      examples [
        "organization :acme_corp, type: :enterprise",
        """
        organization :tech_startup do
          department :engineering do
            team :backend do
              member :alice, position: "Senior Engineer"
            end

            team :frontend do
              member :bob, position: "Frontend Developer"
            end
          end

          department :sales do
            team :enterprise do
              member :charlie, position: "Sales Manager"
            end
          end
        end
        """
      ]
    end
  end

  # Define sections
  sections do
    section :organizations do
      entities [:organization]
      describe "Configure organizations"
      schema [
        primary_org: [type: :atom, doc: "Primary organization"]
      ]
    end
  end

  # Configure extension
  extension do
    sections [:organizations]
  end
end
