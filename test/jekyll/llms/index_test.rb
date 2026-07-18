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

  def test_uses_title_and_description_overrides
    content = index(
      site: site("title" => "Fixture Site", "description" => "Fixture description."),
      entries: [entry(section: "pages", title: "Home", description: "", url: "/")],
      url_for: original_urls,
      title: "Category: fable",
      description: "Posts in fable."
    ).content

    assert_equal <<~TEXT, content
      # Category: fable

      > Posts in fable.

      ## Pages

      - [Home](https://example.com/base/)
    TEXT
  end

  def test_omits_empty_description_override
    content = index(
      site: site("title" => "Fixture Site", "description" => "Fixture description."),
      entries: [entry(section: "pages", title: "Home", description: "", url: "/")],
      url_for: original_urls,
      title: "Garden",
      description: ""
    ).content

    assert_equal <<~TEXT, content
      # Garden


      ## Pages

      - [Home](https://example.com/base/)
    TEXT
  end

  def test_falls_back_to_site_title_and_description_without_overrides
    content = index(
      site: site("title" => "Fixture Site", "description" => " Fixture description. "),
      entries: [entry(section: "pages", title: "Home", description: "", url: "/")],
      url_for: original_urls
    ).content

    assert_equal <<~TEXT, content
      # Fixture Site

      > Fixture description.

      ## Pages

      - [Home](https://example.com/base/)
    TEXT
  end

  def test_allows_omitting_site_when_title_and_description_overrides_are_provided
    content = Jekyll::Llms::Index.new(
      entries: [entry(section: "pages", title: "Home", description: "", url: "/")],
      url_for: original_urls,
      title: "Category: fable",
      description: "Category: fable"
    ).content

    assert_equal <<~TEXT, content
      # Category: fable

      > Category: fable

      ## Pages

      - [Home](https://example.com/base/)
    TEXT
  end

  private

  def index(site:, entries:, url_for:, title: nil, description: nil)
    kwargs = { site: site, entries: entries, url_for: url_for }
    kwargs[:title] = title unless title.nil?
    kwargs[:description] = description unless description.nil?
    Jekyll::Llms::Index.new(**kwargs)
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
