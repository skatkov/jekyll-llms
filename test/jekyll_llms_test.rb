# frozen_string_literal: true

require "test_helper"

class JekyllLlmsTest < Minitest::Test
  cover "Jekyll::Llms"

  def test_hook_generates_llms_txt_and_markdown_sidecars
    build_site({}, {
      "index.html" => <<~HTML,
        ---
        title: Home
        description: Home page.
        ---

        <h1>{{ site.title }}</h1>
      HTML
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Home](https://example.com/base/index.md): Home page."
      assert_equal "<h1>Fixture Site</h1>\n", read_output(destination, "index.md")
    end
  end
end
