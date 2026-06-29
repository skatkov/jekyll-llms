# frozen_string_literal: true

require "test_helper"

class JekyllLlmsIndexTest < Minitest::Test
  cover "Jekyll::Llms::Index"

  def test_renders_title_description_sections_and_markdown_links
    entries = [
      entry(section: "pages", title: "Home", description: "Home page.", url: "/"),
      entry(section: "api_guides", title: "Intro", description: "", url: "/guides/intro"),
    ]

    content = index(
      site: site("title" => "Fixture Site", "description" => " Fixture description. "),
      entries: entries,
      url_for: markdown_urls
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
    content = index(
      site: site({}),
      entries: [entry(section: "pages", title: "Home", description: "", url: "/")],
      url_for: original_urls
    ).content

    assert_equal <<~TEXT, content
      # Jekyll Site


      ## Pages

      - [Home](https://example.com/base/)
    TEXT
  end

  def test_keeps_original_links_for_non_markdown_sources
    content = index(
      site: site({}),
      entries: [entry(section: "pages", title: "Home", description: "", url: "/", relative_path: "index.html")],
      url_for: original_urls
    ).content

    assert_includes content, "- [Home](https://example.com/base/)"
    refute_includes content, "index.md"
  end

  def test_uses_supplied_entry_urls
    content = index(
      site: site({}),
      entries: [entry(section: "pages", title: "Home", description: "", url: "/")],
      url_for: ->(_entry) { "https://example.com/custom" }
    ).content

    assert_includes content, "- [Home](https://example.com/custom)"
  end

  private

  def index(site:, entries:, url_for:)
    Jekyll::Llms::Index.new(site: site, entries: entries, url_for: url_for)
  end

  def markdown_urls
    ->(entry) { entry.url.absolute(markdown: true) }
  end

  def original_urls
    ->(entry) { entry.url.absolute(markdown: false) }
  end

  def site(config)
    defaults = {
      "url" => "https://example.com/",
      "baseurl" => "/base/",
    }
    Struct.new(:config).new(defaults.merge(config))
  end

  def entry(section:, title:, description:, url:, relative_path: markdown_relative_path(url))
    item = Struct.new(:url, :relative_path, :data, :name).new(
      url,
      relative_path,
      { "title" => title, "description" => description },
      "entry.md"
    )

    Jekyll::Llms::Entry.new(site: site({}), item: item, section: section)
  end

  def markdown_relative_path(url)
    path = url.delete_prefix("/")
    path.empty? ? "index.md" : "#{path}.md"
  end
end
