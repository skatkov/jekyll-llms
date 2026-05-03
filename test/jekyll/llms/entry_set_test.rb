# frozen_string_literal: true

require "test_helper"

class JekyllLlmsEntrySetTest < Minitest::Test
  cover "Jekyll::Llms::EntrySet"

  def test_reads_pages_for_pages_section
    first = item(url: "/first")
    second = item(url: "/second")
    entries = entries_for(site(pages: [first, second]), include: ["pages"])

    assert_equal [first, second], entries.map(&:item)
    assert_equal %w[pages pages], entries.map(&:section)
    assert_equal "https://example.com/first.md", entries.first.url.absolute(markdown: true)
  end

  def test_reads_posts_sorted_newest_first
    older = sortable_item(url: "/blog/older", order: 1)
    newer = sortable_item(url: "/blog/newer", order: 2)
    entries = entries_for(site(posts: [older, newer]), include: ["posts"])

    assert_equal [newer, older], entries.map(&:item)
  end

  def test_reads_output_collection_docs
    doc = item(url: "/guides/intro")
    collection = collection(docs: [doc], write: true)
    entries = entries_for(site(collections: { "guides" => collection }), include: ["guides"])

    assert_equal [doc], entries.map(&:item)
    assert_equal ["guides"], entries.map(&:section)
  end

  def test_skips_non_output_and_unknown_collections
    hidden = item(url: "/components/card")
    collections = { "components" => collection(docs: [hidden], write: false) }

    assert_empty entries_for(site(collections: collections), include: ["components"])
    assert_empty entries_for(site(collections: collections), include: ["unknown"])
  end

  def test_filters_disabled_and_excluded_entries
    keep = item(url: "/keep")
    disabled = item(url: "/disabled", data: { "llms" => false })
    excluded = item(url: "/excluded")
    entries = entries_for(site(pages: [keep, disabled, excluded]), include: ["pages"], exclude: ["/excluded"])

    assert_equal [keep], entries.map(&:item)
  end

  def test_deduplicates_entries_by_item_url
    page = item(url: "/duplicate", name: "page.md")
    guide = item(url: "/duplicate", name: "guide.md")
    collections = { "guides" => collection(docs: [guide], write: true) }
    entries = entries_for(site(pages: [page], collections: collections), include: %w[pages guides])

    assert_equal [page], entries.map(&:item)
  end

  private

  def entries_for(site, include:, exclude: [])
    config = Jekyll::Llms::Config.new("include" => include, "exclude" => exclude)

    Jekyll::Llms::EntrySet.new(site: site, config: config).entries
  end

  def site(pages: [], posts: [], collections: {})
    Struct.new(:pages, :posts, :collections, :config).new(
      pages,
      Struct.new(:docs).new(posts),
      collections,
      { "url" => "https://example.com", "baseurl" => "" }
    )
  end

  def item(url:, relative_path: nil, data: {}, name: nil)
    relative_path ||= "#{url.delete_prefix("/")}.md"
    name ||= File.basename(relative_path)
    Struct.new(:url, :relative_path, :data, :name).new(url, relative_path, data, name)
  end

  def sortable_item(url:, order:)
    Class.new do
      include Comparable

      attr_reader :url, :relative_path, :data, :name, :order

      def initialize(url, order)
        @url = url
        @relative_path = "#{url.delete_prefix("/")}.md"
        @data = {}
        @name = File.basename(@relative_path)
        @order = order
      end

      def <=>(other)
        order <=> other.order
      end
    end.new(url, order)
  end

  def collection(docs:, write:)
    Class.new do
      attr_reader :docs

      def initialize(docs, write)
        @docs = docs
        @write = write
      end

      def write?
        @write
      end
    end.new(docs, write)
  end
end
