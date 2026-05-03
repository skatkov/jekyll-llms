# frozen_string_literal: true

require "test_helper"

class JekyllLlmsEntryTest < Minitest::Test
  cover "Jekyll::Llms::Entry"

  def test_exposes_item_section_and_url
    item = item(data: { "title" => "Page" })
    entry = entry(item: item, section: "pages")

    assert_same item, entry.item
    assert_equal "pages", entry.section
    assert_instance_of Jekyll::Llms::Url, entry.url
    assert_equal "https://example.com/page.md", entry.url.absolute(markdown: true)
  end

  def test_title_and_description_are_trimmed
    entry = entry(item: item(data: {
      "title" => " Page ",
      "description" => " Description. ",
    }))

    assert_equal "Page", entry.title
    assert_equal "Description.", entry.description
  end

  def test_description_defaults_to_empty_string
    assert_equal "", entry(item: item(data: {})).description
  end

  def test_title_falls_back_to_basename_without_ext_when_available
    item = Class.new do
      attr_reader :url, :relative_path, :data, :name

      def initialize
        @url = "/guide"
        @relative_path = "guide.md"
        @data = { "title" => "" }
        @name = "ignored.md"
      end

      def basename_without_ext
        "guide"
      end
    end.new

    assert_equal "guide", entry(item: item).title
  end

  def test_title_falls_back_to_item_name
    assert_equal "guide", entry(item: item(data: {}, name: "guide.md")).title
  end

  def test_enabled_defaults_to_true_and_respects_frontmatter_opt_out
    assert_predicate entry(item: item(data: {})), :enabled?
    refute_predicate entry(item: item(data: { "llms" => false })), :enabled?
  end

  def test_excluded_by_checks_url_candidates
    entry = entry(item: item(url: "/docs", relative_path: "docs.md"))

    assert entry.excluded_by?(["/docs.md"])
    assert entry.excluded_by?(["/posts/**", "/docs.md"])
    refute entry.excluded_by?(["/posts/**"])
  end

  private

  def entry(item:, section: "pages")
    Jekyll::Llms::Entry.new(site: site, item: item, section: section)
  end

  def item(url: "/page", relative_path: "page.md", data: {}, name: "page.md")
    Struct.new(:url, :relative_path, :data, :name).new(url, relative_path, data, name)
  end

  def site
    Struct.new(:config).new({ "url" => "https://example.com", "baseurl" => "" })
  end
end
