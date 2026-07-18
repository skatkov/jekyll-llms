# frozen_string_literal: true

require "test_helper"

class JekyllLlmsTest < Minitest::Test
  cover "Jekyll::Llms"

  def test_scope_builders_starts_empty
    assert_equal [], Jekyll::Llms.scope_builders
  end

  def test_register_scope_builder_appends_in_order_and_returns_block
    first = ->(*) { [] }
    second = ->(*) { [] }

    returned_first = Jekyll::Llms.register_scope_builder(&first)
    returned_second = Jekyll::Llms.register_scope_builder(&second)

    assert_same first, returned_first
    assert_same second, returned_second
    assert_equal [first, second], Jekyll::Llms.scope_builders
  end

  # Without a block, fail immediately instead of appending nil for a later NoMethodError.
  def test_register_scope_builder_requires_a_block
    error = assert_raises(ArgumentError) do
      Jekyll::Llms.register_scope_builder
    end

    assert_match(/block/i, error.message)
    assert_equal [], Jekyll::Llms.scope_builders
  end

  def test_reset_scope_builders_clears_registry
    Jekyll::Llms.register_scope_builder { [] }

    Jekyll::Llms.reset_scope_builders!

    assert_equal [], Jekyll::Llms.scope_builders
  end

  def test_hook_generates_markdown_sidecars_only_for_markdown_sources
    build_site({}, {
      "_layouts/default.html" => <<~HTML,
        <html><head><title>{{ page.title }}</title></head><body>{{ content }}</body></html>
      HTML
      "index.html" => <<~HTML,
        ---
        layout: default
        title: Home
        description: Home page.
        ---

        <h1>{{ site.title }}</h1>
      HTML
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        description: Page body.
        ---

        Page {{ site.title }}.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Home](https://example.com/base/): Home page."
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/base/page.md): Page body."
      refute_path_exists output_path(destination, "index.md")
      assert_equal "Page Fixture Site.\n", read_output(destination, "page.md")
      refute_includes read_output(destination, "index.html"), %(type="text/markdown")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end
end
