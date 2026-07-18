# frozen_string_literal: true

require "test_helper"

class JekyllLlmsFullIndexTest < Minitest::Test
  cover "Jekyll::Llms::FullIndex"

  # Renders H1 from scope title, H2 + body per markdown entry, blank lines between entries.
  def test_renders_title_and_markdown_entries
    content = full_index(
      title: "Fixture Site",
      entries: [
        ["Page One", "Body one.\n"],
        ["Page Two", "Body two.\n"],
      ]
    ).content

    assert_equal <<~TEXT, content
      # Fixture Site

      ## Page One

      Body one.

      ## Page Two

      Body two.
    TEXT
  end

  # Entries without bodies are omitted from the corpus.
  def test_skips_entries_without_bodies
    content = full_index(
      title: "Fixture Site",
      entries: [
        ["Missing", nil],
        ["Empty", ""],
        ["Present", "Present body.\n"],
      ]
    ).content

    assert_equal <<~TEXT, content
      # Fixture Site

      ## Present

      Present body.
    TEXT
  end

  private

  def full_index(title:, entries:)
    Jekyll::Llms::FullIndex.new(title: title, entries: entries)
  end
end
