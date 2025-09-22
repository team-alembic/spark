defmodule Spark.Test.TeamDslExample do
  @moduledoc """
  Example DSL builder usage with nested entities.

  This demonstrates a team management DSL with nested structures:
  - Teams contain members and projects
  - Projects contain tasks
  """

  use Spark.DslBuilder

  # Define target structs
  defmodule Team do
    defstruct [:name, :description, members: [], projects: [], __identifier__: nil]
  end

  defmodule Member do
    defstruct [:name, :role, :email, __identifier__: nil]
  end

  defmodule Project do
    defstruct [:name, :status, :deadline, tasks: [], __identifier__: nil]
  end

  defmodule Task do
    defstruct [:name, :priority, :completed, __identifier__: nil]
  end

  # Define entities using DSL Builder
  entities do
    entity :task do
      target Spark.Test.TeamDslExample.Task
      args [:name]
      schema [
        name: [type: :atom, required: true, doc: "Task name"],
        priority: [type: {:in, [:low, :medium, :high]}, default: :medium, doc: "Task priority"],
        completed: [type: :boolean, default: false, doc: "Whether task is completed"]
      ]
      describe "Defines a task within a project"
      examples ["task :implement_feature, priority: :high"]
    end

    entity :member do
      target Spark.Test.TeamDslExample.Member
      args [:name]
      schema [
        name: [type: :atom, required: true, doc: "Member name"],
        role: [type: {:in, [:developer, :designer, :manager, :qa]}, required: true, doc: "Member role"],
        email: [type: :string, doc: "Member email address"]
      ]
      describe "Defines a team member"
      examples ["member :john, role: :developer, email: \"john@example.com\""]
    end

    entity :project do
      target Spark.Test.TeamDslExample.Project
      args [:name]
      entities [:task]
      schema [
        name: [type: :atom, required: true, doc: "Project name"],
        status: [type: {:in, [:planning, :active, :completed]}, default: :planning, doc: "Project status"],
        deadline: [type: :string, doc: "Project deadline"]
      ]
      describe "Defines a project with tasks"
      examples [
        "project :web_app, status: :active",
        """
        project :mobile_app do
          task :design_ui
          task :implement_backend
        end
        """
      ]
    end

    entity :team do
      target Spark.Test.TeamDslExample.Team
      args [:name]
      entities [:member, :project]
      schema [
        name: [type: :atom, required: true, doc: "Team name"],
        description: [type: :string, doc: "Team description"]
      ]
      describe "Defines a team with members and projects"
      examples [
        "team :engineering, description: \"Engineering team\"",
        """
        team :engineering do
          member :alice, role: :manager
          member :bob, role: :developer

          project :new_feature do
            task :research
            task :implement
          end
        end
        """
      ]
    end
  end

  # Define sections using DSL Builder
  sections do
    section :teams do
      entities [:team]
      describe "Configure teams in the organization"
      schema [
        default_team: [type: :atom, doc: "Default team for new members"]
      ]
    end
  end

  # Configure extension
  extension do
    sections [:teams]
  end
end
