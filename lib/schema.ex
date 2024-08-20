defmodule Example.Document do
  use Ecto.Schema
  @primary_key false

  import Ecto.Changeset
  import PolymorphicEmbed

  @type t :: %Example.Document{
          id: Ecto.UUID.t(),
          type: String.t(),
          children: [Example.Heading.t() | Example.Text.t()]
        }

  embedded_schema do
    field(:id, Ecto.UUID)
    field(:type, :string)

    polymorphic_embeds_many(:children,
      types: [
        heading: Example.Heading,
        text: Example.Text
      ],
      type_field_name: :type,
      on_replace: :delete,
      on_type_not_found: :changeset_error
    )
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [:id, :type])
    |> cast_polymorphic_embed(:children)
    |> validate_required([:id, :type])
    |> validate_inclusion(:type, ["document"])
  end

  @spec parse(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def parse(map) do
    changeset = changeset(%Example.Document{}, map)

    if changeset.valid? do
      document = Ecto.Changeset.apply_changes(changeset)
      {:ok, document}
    else
      {:error, changeset}
    end
  end
end

defmodule Example.Heading do
  use Ecto.Schema
  @primary_key false

  import Ecto.Changeset

  @type t :: %Example.Heading{
          id: Ecto.UUID.t(),
          type: String.t(),
          level: integer(),
          children: [Example.Text.t()]
        }

  embedded_schema do
    field(:id, Ecto.UUID)
    field(:type, :string)
    field(:level, :integer)
    embeds_many(:children, Example.Text)
  end

  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(heading, attrs) do
    heading
    |> cast(attrs, [:id, :type, :level])
    |> cast_embed(:children)
    |> validate_required([:id, :type, :level])
    |> validate_inclusion(:type, ["heading"])
  end
end

defmodule Example.Text do
  use Ecto.Schema
  @primary_key false

  import Ecto.Changeset

  @type t :: %Example.Text{
          id: Ecto.UUID.t(),
          type: String.t(),
          text: String.t()
        }

  embedded_schema do
    field(:id, Ecto.UUID)
    field(:type, :string)
    field(:text, :string)
  end

  @spec changeset(struct(), map()) :: Ecto.Changeset.t()
  def changeset(text, attrs) do
    text
    |> cast(attrs, [:id, :type, :text])
    |> validate_required([:id, :type, :text])
    |> validate_inclusion(:type, ["text"])
  end
end
