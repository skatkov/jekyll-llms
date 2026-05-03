# frozen_string_literal: true

require "test_helper"

class JekyllLlmsIndexTest < Minitest::Test
  cover "Jekyll::Llms::Index"

  def test_renders_title_description_sections_and_markdown_links
    content = Jekyll::Llms::Index.new(
      site: site("title" => "Fixture Site", "description" => " Fixture description. "),
      entries: [
        entry(section: "pages", title: "Home", description: "Home page.", url: "/"),
        entry(section: "api_guides", title: "Intro", description: "", url: "/guides/intro"),
      ],
      markdown: true
    ).content

    assert_equal <<~TEXT, content
      # Fixture Site

      > Fixture description.

      ## Pages

      - [Home](https://example.com/base/index.md): Home page.

      ## Api Guides

      - [Intro](https://example.com/base/guides/intro.md)
    TEXT
  end

  def test_uses_default_title_omits_missing_description_and_keeps_original_links
    content = Jekyll::Llms::Index.new(
      site: site({}),
      entries: [entry(section: "pages", title: "Home", description: "", url: "/")],
      markdown: false
    ).content

    assert_equal <<~TEXT, content
      # Jekyll Site


      ## Pages

      - [Home](https://example.com/base/)
    TEXT
  end

  private

  def site(config)
    defaults = {
      "url" => "https://example.com/",
      "baseurl" => "/base/",
    }
    Struct.new(:config).new(defaults.merge(config))
  end

  def entry(section:, title:, description:, url:)
    item = Struct.new(:url, :relative_path, :data, :name).new(
      url,
      "#{url.delete_prefix("/")}.md",
      { "title" => title, "description" => description },
      "entry.md"
    )

    Jekyll::Llms::Entry.new(site: site({}), item: item, section: section)
  end
end
