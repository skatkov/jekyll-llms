# frozen_string_literal: true

require "test_helper"

class JekyllLlmsSiteWriterTest < Minitest::Test
  cover "Jekyll::Llms::SiteWriter"

  def test_writes_index_and_markdown_files
    build_site({}, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        description: Page description.
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/base/page.md): Page description."
      assert_equal "Page body.\n", read_output(destination, "page.md")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end

  def test_can_disable_llms_txt_while_keeping_markdown_files
    build_site({ "llms" => { "markdown" => true, "llms_txt" => false, "include" => ["pages"], "exclude" => [] } }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      refute_path_exists output_path(destination, "llms.txt")
      assert_equal "Page body.\n", read_output(destination, "page.md")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end

  def test_can_disable_markdown_files_while_keeping_original_index_links
    build_site({ "baseurl" => "", "llms" => { "markdown" => false, "llms_txt" => true, "include" => ["pages"], "exclude" => [] } }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/page)"
      refute_path_exists output_path(destination, "page.md")
      refute_includes read_output(destination, "page.html"), %(type="text/markdown")
    end
  end

  private

  def default_layout
    "<html><head><title>{{ page.title }}</title></head><body>{{ content }}</body></html>\n"
  end
end
