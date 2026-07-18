# frozen_string_literal: true

require "test_helper"

class JekyllLlmsScopeEnumeratorTest < Minitest::Test
  cover "Jekyll::Llms::ScopeEnumerator"
  cover "Jekyll::Llms::Scope"

  # One scope per site.categories key; entries intersect root EntrySet; path uses template + slug.
  def test_builds_category_scopes_from_site_categories
    kept = item(url: "/blog/kept")
    other = item(url: "/blog/other")
    entry = entry_for(kept, section: "posts")
    site = site(
      categories: { "My Category" => [kept], "empty" => [other] },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )
    config = config(categories: true)

    scopes = scopes_for(site: site, config: config, entries: [entry])

    assert_equal 1, scopes.length
    scope = scopes.first
    assert_equal "/category/my-category/", scope.path_prefix
    assert_equal "My Category", scope.title
    assert_equal "Category: My Category", scope.description
    assert_equal [entry], scope.entries
  end

  # Uses jekyll-archives category permalink template when configured.
  def test_uses_archives_category_path_template
    post = item(url: "/blog/post")
    entry = entry_for(post, section: "posts")
    site = site(
      categories: { "fable" => [post] },
      config: {
        "url" => "https://example.com",
        "baseurl" => "",
        "jekyll-archives" => { "permalinks" => { "category" => "/topics/:name/" } },
      }
    )

    scopes = scopes_for(site: site, config: config(categories: true), entries: [entry])

    assert_equal "/topics/fable/", scopes.first.path_prefix
  end

  # Soft-reads jekyll-archives.slug_mode when slugifying category :name for the path.
  def test_uses_archives_slug_mode_for_category_path
    post = item(url: "/blog/post")
    entry = entry_for(post, section: "posts")
    site = site(
      categories: { "Café" => [post] },
      config: {
        "url" => "https://example.com",
        "baseurl" => "",
        "jekyll-archives" => { "slug_mode" => "ascii" },
      }
    )

    scopes = scopes_for(site: site, config: config(categories: true), entries: [entry])

    assert_equal "/category/caf/", scopes.first.path_prefix
  end

  # One scope per included writeable collection label (not pages/posts); path /{label}/.
  def test_builds_collection_scopes_for_included_writeable_collections
    garden_doc = item(url: "/garden/note")
    notes_doc = item(url: "/notes/idea")
    garden_entry = entry_for(garden_doc, section: "garden")
    notes_entry = entry_for(notes_doc, section: "notes")
    site = site(
      collections: {
        "garden" => collection(docs: [garden_doc], write: true),
        "notes" => collection(docs: [notes_doc], write: true),
        "drafts" => collection(docs: [item(url: "/drafts/x")], write: false),
      },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )
    config = config(collections: true, include: %w[pages posts garden notes])

    scopes = scopes_for(site: site, config: config, entries: [garden_entry, notes_entry])

    assert_equal 2, scopes.length
    garden_scope, notes_scope = scopes
    assert_equal "/garden/", garden_scope.path_prefix
    assert_equal "garden", garden_scope.title
    assert_equal "Collection: garden", garden_scope.description
    assert_equal [garden_entry], garden_scope.entries
    assert_equal "/notes/", notes_scope.path_prefix
    assert_equal [notes_entry], notes_scope.entries
  end

  # Flags off yield no scopes even when membership data would otherwise produce scopes.
  def test_returns_empty_when_flags_off
    post = item(url: "/blog/post")
    doc = item(url: "/garden/n")
    post_entry = entry_for(post, section: "posts")
    garden_entry = entry_for(doc, section: "garden")
    site = site(
      categories: { "fable" => [post] },
      collections: { "garden" => collection(docs: [doc], write: true) },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )

    assert_empty scopes_for(
      site: site,
      config: config(include: %w[posts garden]),
      entries: [post_entry, garden_entry]
    )
  end

  # Zero-entry scopes after intersection are omitted.
  def test_omits_scopes_with_zero_entries
    outside = item(url: "/blog/outside")
    site = site(
      categories: { "fable" => [outside] },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )
    kept = entry_for(item(url: "/blog/kept"), section: "posts")

    assert_empty scopes_for(site: site, config: config(categories: true), entries: [kept])
  end

  # Empty collection intersections are omitted without blocking later non-empty collections.
  def test_omits_empty_collection_scopes_without_blocking_later_scopes
    garden_doc = item(url: "/garden/n")
    notes_doc = item(url: "/notes/x")
    garden_entry = entry_for(garden_doc, section: "garden")
    site = site(
      collections: {
        "notes" => collection(docs: [notes_doc], write: true),
        "garden" => collection(docs: [garden_doc], write: true),
      },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )

    scopes = scopes_for(
      site: site,
      config: config(collections: true, include: %w[notes garden]),
      entries: [garden_entry]
    )

    assert_equal 1, scopes.length
    assert_equal "/garden/", scopes.first.path_prefix
    assert_equal [garden_entry], scopes.first.entries
  end

  # pages/posts labels never become collection scopes even when present as writeable collections.
  def test_skips_pages_and_posts_for_collection_scopes
    post = item(url: "/blog/post")
    page = item(url: "/about")
    site = site(
      collections: {
        "posts" => collection(docs: [post], write: true),
        "pages" => collection(docs: [page], write: true),
      },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )

    assert_empty scopes_for(
      site: site,
      config: config(collections: true, include: %w[pages posts]),
      entries: [entry_for(post, section: "posts"), entry_for(page, section: "pages")]
    )
  end

  # Unknown and non-writeable collection labels are skipped without raising; later writeable labels still emit.
  def test_skips_unknown_and_non_writeable_collections_without_stopping
    hidden_doc = item(url: "/drafts/x")
    garden_doc = item(url: "/garden/n")
    site = site(
      collections: {
        "drafts" => collection(docs: [hidden_doc], write: false),
        "garden" => collection(docs: [garden_doc], write: true),
      },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )

    scopes = scopes_for(
      site: site,
      config: config(collections: true, include: %w[missing drafts garden]),
      entries: [
        entry_for(hidden_doc, section: "drafts"),
        entry_for(garden_doc, section: "garden"),
      ]
    )

    assert_equal 1, scopes.length
    assert_equal "/garden/", scopes.first.path_prefix
    refute_includes scopes.map(&:path_prefix), "/drafts/"
    refute_includes scopes.map(&:path_prefix), "/missing/"
  end

  # Duplicate include labels must not emit duplicate collection scopes (EntrySet tolerates dupes).
  def test_deduplicates_repeated_collection_include_labels
    garden_doc = item(url: "/garden/n")
    garden_entry = entry_for(garden_doc, section: "garden")
    site = site(
      collections: { "garden" => collection(docs: [garden_doc], write: true) },
      config: { "url" => "https://example.com", "baseurl" => "" }
    )

    scopes = scopes_for(
      site: site,
      config: config(collections: true, include: %w[garden garden]),
      entries: [garden_entry]
    )

    assert_equal 1, scopes.length
    assert_equal "/garden/", scopes.first.path_prefix
    assert_equal [garden_entry], scopes.first.entries
  end

  private

  def scopes_for(site:, config:, entries:)
    Jekyll::Llms::ScopeEnumerator.new(site: site, config: config, entries: entries).scopes
  end

  def config(categories: false, collections: false, include: %w[pages posts])
    Jekyll::Llms::Config.new(
      Jekyll::Llms::Config::DEFAULTS.merge(
        "categories" => categories,
        "collections" => collections,
        "include" => include
      )
    )
  end

  def site(categories: {}, collections: {}, config:)
    Struct.new(:categories, :collections, :config, :pages, :posts).new(
      categories,
      collections,
      config,
      [],
      Struct.new(:docs).new([])
    )
  end

  def entry_for(item, section:)
    Jekyll::Llms::Entry.new(
      site: Struct.new(:config).new({ "url" => "https://example.com", "baseurl" => "" }),
      item: item,
      section: section
    )
  end

  def item(url:, relative_path: nil, data: {}, name: nil)
    relative_path ||= "#{url.delete_prefix("/")}.md"
    name ||= File.basename(relative_path)
    Struct.new(:url, :relative_path, :data, :name).new(url, relative_path, data, name)
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
