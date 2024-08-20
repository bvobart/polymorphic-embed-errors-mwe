defmodule Example.SchemaTest do
  use ExUnit.Case, async: true

  @id Ecto.UUID.generate()
  @valid_document_map %{
    "id" => @id,
    "type" => "document",
    "children" => [
      %{
        "id" => @id,
        "type" => "heading",
        "level" => 1,
        "children" => [
          %{
            "id" => @id,
            "type" => "text",
            "text" => "Hello, world!"
          }
        ]
      },
      %{
        "id" => @id,
        "type" => "text",
        "text" => "Goodbye, world!"
      }
    ]
  }

  test "parses a valid document" do
    assert Example.Document.parse(@valid_document_map) ==
             {:ok,
              %Example.Document{
                id: @id,
                type: "document",
                children: [
                  %Example.Heading{
                    id: @id,
                    type: "heading",
                    level: 1,
                    children: [
                      %Example.Text{
                        id: @id,
                        type: "text",
                        text: "Hello, world!"
                      }
                    ]
                  },
                  %Example.Text{
                    id: @id,
                    type: "text",
                    text: "Goodbye, world!"
                  }
                ]
              }}
  end

  test "rejects a document with an invalid child type (error comes from PolymorphicEmbed)" do
    invalid_document_map =
      Map.put(@valid_document_map, "children", [%{"id" => @id, "type" => "invalid"}])

    assert {:error, changeset} = Example.Document.parse(invalid_document_map)

    # This is the error I currently get, which is not very descriptive:

    assert changeset.errors == [children: {"is invalid", []}]

    # Imagine having a document with 1000s of children, and one or more objects under one or more of them is invalid,
    # then good luck finding it, especially with more types of elements and deeper nesting.

    # What I would want is something more descriptive regarding which element is invalid, e.g.:

    # assert changeset.errors == [
    #          children:
    #            {"has invalid elements",
    #             [
    #               validation: :polymorphic_embeds_many,
    #               errors: [
    #                 %{
    #                   index: 0,
    #                   field: "type",
    #                   error: {"is invalid", [validation: :inclusion, enum: ["heading", "text"]]}
    #                 }
    #               ]
    #             ]}
    #        ]

    # Or, to make it more similar to what Ecto does for embed_many:

    # child_changeset = changeset.changes[:children] |> Enum.at(0)

    # assert child_changeset.errors == [
    #          type: {"is invalid", [validation: :inclusion, enum: ["heading", "text"]]}
    #        ]

    # However, currently:

    assert changeset.changes[:children] == nil

    # So this would require the changesets of every child to be placed on changeset.changes[:children],
    # which I believe might be related to https://github.com/mathieuprog/polymorphic_embed/issues/74

    # Note: PolymorphicEmbed.traverse_errors/2 doesn't really help here
    PolymorphicEmbed.traverse_errors(changeset, fn changeset, field, error ->
      IO.inspect(changeset: changeset, field: field, error: error)
    end)
  end

  test "rejects a document with an invalid grandchild type (error comes through PolymorphicEmbed, but from Ecto embed_many)" do
    invalid_document_map =
      Map.put(@valid_document_map, "children", [
        %{
          "id" => @id,
          "type" => "heading",
          "level" => 1,
          "children" => [
            %{
              "id" => @id,
              "type" => "invalid",
              "text" => "Hello, world!"
            }
          ]
        }
      ])

    assert {:error, changeset} = Example.Document.parse(invalid_document_map)
    heading_changeset = changeset.changes[:children] |> Enum.at(0)
    text_changeset = heading_changeset.changes[:children] |> Enum.at(0)

    # Luckily, this error is more descriptive, as it originates from an Ecto embed_many and none of the polymorphic embeds are broken:

    assert changeset.errors == []
    assert heading_changeset.errors == []

    assert text_changeset.errors == [
             type: {"is invalid", [validation: :inclusion, enum: ["text"]]}
           ]
  end

  test "rejects a document with an invalid child field" do
    invalid_document_map =
      Map.put(@valid_document_map, "children", [
        %{"id" => @id, "type" => "heading", "invalid" => "invalid"}
      ])

    assert {:error, changeset} = Example.Document.parse(invalid_document_map)
    child_changeset = changeset.changes[:children] |> Enum.at(0)

    # Luckily, this error is also more descriptive:

    assert changeset.errors == []
    assert child_changeset.errors == [level: {"can't be blank", [validation: :required]}]
  end
end
