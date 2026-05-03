# frozen_string_literal: true

require "test_helper"

class JekyllLlmsMarkdownSourceTest < Minitest::Test
  cover "Jekyll::Llms::MarkdownSource"

  def test_reads_source_body_and_renders_liquid
    build_site(markdown_disabled_config, {
      "docs.md" => <<~MARKDOWN,
        ---
        title: Documentation
        ---

        # {{ page.title }}

        Welcome to {{ site.title }}.
      MARKDOWN
    }) do |site, _destination|
      item = site.pages.detect { |page| page.relative_path == "docs.md" }
      site.liquid_renderer.cache.clear

      assert_equal "# Documentation\n\nWelcome to Fixture Site.\n", Jekyll::Llms::MarkdownSource.new(site: site, item: item).content
    end
  end

  def test_respects_render_with_liquid_false
    build_site(markdown_disabled_config, {
      "raw.md" => <<~MARKDOWN,
        ---
        title: Raw
        render_with_liquid: false
        ---

        Raw {{ site.title }}.
      MARKDOWN
    }) do |site, _destination|
      item = site.pages.detect { |page| page.relative_path == "raw.md" }
      site.liquid_renderer.cache.clear

      assert_equal "Raw {{ site.title }}.\n", Jekyll::Llms::MarkdownSource.new(site: site, item: item).content
    end
  end

  private

  def markdown_disabled_config
    {
      "llms" => {
        "markdown" => false,
        "llms_txt" => false,
        "include" => ["pages"],
        "exclude" => [],
      },
    }
  end
end
