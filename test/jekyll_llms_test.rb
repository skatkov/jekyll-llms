# frozen_string_literal: true

require "test_helper"

class JekyllLlmsTest < Minitest::Test
  cover "Jekyll::Llms"

  def test_hook_generates_llms_txt_and_markdown_sidecars
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
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Home](https://example.com/base/index.md): Home page."
      assert_equal "<h1>Fixture Site</h1>\n", read_output(destination, "index.md")
      assert_includes read_output(destination, "index.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/index.md">)
    end
  end
end
