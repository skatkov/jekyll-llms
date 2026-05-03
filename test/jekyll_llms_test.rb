# frozen_string_literal: true

require "test_helper"

class JekyllLlmsTest < Minitest::Test
  cover "Jekyll::Llms*"

  def test_generates_llms_txt_and_markdown_sidecars
    build_site({}, default_files) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      assert_includes llms_txt, "# Fixture Site"
      assert_includes llms_txt.lines, "> Fixture description.\n"
      assert_includes llms_txt, "## Pages"
      assert_includes llms_txt.lines, "- [Home](https://example.com/base/index.md): Home page.\n"
      assert_includes llms_txt, "- [Documentation](https://example.com/base/docs.md): Docs page."
      assert_includes llms_txt, "## Posts"
      assert_includes llms_txt, "- [Newer post](https://example.com/base/blog/newer.md): Fresh post."
      assert_includes llms_txt.lines, "- [Older post](https://example.com/base/blog/older.md)\n"

      assert_operator llms_txt.index("Newer post"), :<, llms_txt.index("Older post")

      refute_includes llms_txt, "Hidden post"
      refute_includes llms_txt, "Secret"
      refute_includes llms_txt, "Not Found"
      refute_includes llms_txt, "Asset"
      refute_includes llms_txt, "Unpublished"
      refute_includes llms_txt, "URL Skip"
      refute_includes llms_txt, "Markdown Skip"

      assert_equal "<h1>Fixture Site</h1>\n", read_output(destination, "index.md")
      assert_equal "# Docs\n\nWelcome to Fixture Site Documentation.\n", read_output(destination, "docs.md")
      assert_equal "Newer Fixture Site.\n", read_output(destination, "blog/newer.md")
      assert_equal "Older post body.\n", read_output(destination, "blog/older.md")

      refute_path_exists output_path(destination, "secret.md")
      refute_path_exists output_path(destination, "404.md")
      refute_path_exists output_path(destination, "assets/asset.md")
      refute_path_exists output_path(destination, "blog/hidden.md")
      refute_path_exists output_path(destination, "unpublished.md")
      refute_path_exists output_path(destination, "url-skip.md")
      refute_path_exists output_path(destination, "markdown-output.md")
    end
  end

  def test_uses_original_urls_when_markdown_generation_is_disabled
    config = {
      "baseurl" => "",
      "llms" => {
        "markdown" => false,
        "llms_txt" => true,
        "include" => %w[pages posts],
      },
    }

    build_site(config, {
      "plain.md" => <<~MARKDOWN,
        ---
        title: Plain Page
        ---

        Plain page body.
      MARKDOWN
      "_posts/2024-01-01-post.md" => <<~MARKDOWN,
        ---
        title: Plain Post
        ---

        Plain post body.
      MARKDOWN
    }) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      assert_includes llms_txt, "- [Plain Page](https://example.com/plain)"
      assert_includes llms_txt, "- [Plain Post](https://example.com/blog/post)"

      refute_path_exists output_path(destination, "plain.md")
      refute_path_exists output_path(destination, "blog/post.md")
    end
  end

  def test_deduplicates_entries_by_url
    config = {
      "collections" => {
        "guides" => {
          "output" => true,
          "permalink" => "/:name",
        },
      },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => %w[pages guides],
      },
    }

    build_site(config, {
      "duplicate.md" => <<~MARKDOWN,
        ---
        title: Duplicate Page
        ---

        Duplicate page body.
      MARKDOWN
      "_guides/duplicate.md" => <<~MARKDOWN,
        ---
        title: Duplicate Guide
        ---

        Duplicate guide body.
      MARKDOWN
    }) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      assert_equal 1, llms_txt.scan("https://example.com/base/duplicate.md").count
    end
  end

  def test_can_disable_llms_txt_while_keeping_markdown_sidecars
    config = {
      "llms" => {
        "markdown" => true,
        "llms_txt" => false,
        "include" => ["pages"],
      },
    }

    build_site(config, {
      "page.md" => <<~MARKDOWN,
        ---
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      refute_path_exists output_path(destination, "llms.txt")
      assert_equal "Page body.\n", read_output(destination, "page.md")
    end
  end

  def test_respects_render_with_liquid_false_for_sidecars
    config = {
      "llms" => {
        "markdown" => true,
        "llms_txt" => false,
        "include" => ["pages"],
      },
    }

    build_site(config, {
      "raw.md" => <<~MARKDOWN,
        ---
        title: Raw
        render_with_liquid: false
        ---

        Raw {{ site.title }}.
      MARKDOWN
    }) do |_site, destination|
      assert_equal "Raw {{ site.title }}.\n", read_output(destination, "raw.md")
    end
  end

  def test_includes_output_collections_and_fallback_titles
    config = {
      "collections" => {
        "api_guides" => {
          "output" => true,
          "permalink" => "/guides/:name",
        },
      },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => ["pages", "api_guides"],
      },
    }

    build_site(config, {
      "untitled.html" => <<~HTML,
        ---
        ---

        <p>Untitled page.</p>
      HTML
      "data.json" => <<~JSON,
        ---
        title: Data
        ---

        {"name":"fixture"}
      JSON
      "_api_guides/intro.md" => <<~MARKDOWN,
        ---
        title: ""
        ---

        Collection body.
      MARKDOWN
    }) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      assert_includes llms_txt, "## Api Guides"
      assert_includes llms_txt, "- [untitled](https://example.com/base/untitled.md)"
      assert_includes llms_txt, "- [Data](https://example.com/base/data.md)"
      assert_includes llms_txt, "- [intro](https://example.com/base/guides/intro.md)"

      assert_equal "<p>Untitled page.</p>\n", read_output(destination, "untitled.md")
      assert_equal "{\"name\":\"fixture\"}\n", read_output(destination, "data.md")
      assert_equal "Collection body.\n", read_output(destination, "guides/intro.md")
    end
  end

  def test_entry_set_reads_collection_docs_without_requiring_collection_enumerability
    item = Struct.new(:url, :data, :name).new("/guides/fake", {}, "fake.md")
    collection = Class.new do
      attr_reader :docs

      def initialize(docs)
        @docs = docs
      end

      def write?
        true
      end
    end.new([item])
    site = Struct.new(:pages, :posts, :collections).new([], nil, "guides" => collection)
    config = Jekyll::Llms::Config.new("include" => ["guides"], "exclude" => [])

    entries = Jekyll::Llms::EntrySet.new(site: site, config: config).entries

    assert_equal [item], entries.map(&:item)
  end

  def test_entry_set_reads_post_docs_without_requiring_posts_enumerability
    item = Struct.new(:url, :data, :name).new("/blog/fake", {}, "fake.md")
    posts = Struct.new(:docs).new([item])
    site = Struct.new(:pages, :posts, :collections).new([], posts, {})
    config = Jekyll::Llms::Config.new("include" => ["posts"], "exclude" => [])

    entries = Jekyll::Llms::EntrySet.new(site: site, config: config).entries

    assert_equal [item], entries.map(&:item)
  end

  def test_skips_non_output_collections
    config = {
      "collections" => {
        "components" => {
          "output" => false,
        },
      },
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => ["components"],
      },
    }

    build_site(config, {
      "_components/card.md" => <<~MARKDOWN,
        ---
        title: Card
        ---

        Card body.
      MARKDOWN
    }) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      refute_includes llms_txt, "Card"
      refute_path_exists output_path(destination, "components/card.md")
    end
  end

  def test_skips_unknown_collections
    config = {
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => ["unknown"],
      },
    }

    build_site(config, {}) do |_site, destination|
      llms_txt = read_output(destination, "llms.txt")

      refute_includes llms_txt, "## Unknown"
    end
  end

  def test_uses_default_site_title_and_omits_blank_description
    build_site({ "title" => :absent, "description" => :absent }, {}) do |_site, destination|
      assert_equal "# Jekyll Site\n\n", read_output(destination, "llms.txt")
    end
  end

  def test_uses_defaults_when_llms_config_is_absent
    build_site({ "llms" => :absent }, {
      "page.md" => <<~MARKDOWN,
        ---
        title: Default Page
        ---

        Default page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Default Page](https://example.com/base/page.md)"
      assert_equal "Default page body.\n", read_output(destination, "page.md")
    end
  end

  def test_uses_defaults_when_llms_config_is_nil
    build_site({ "llms" => nil }, {
      "page.md" => <<~MARKDOWN,
        ---
        title: Nil Config Page
        ---

        Nil config page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Nil Config Page](https://example.com/base/page.md)"
      assert_equal "Nil config page body.\n", read_output(destination, "page.md")
    end
  end

  private

  def default_files
    {
      "index.html" => <<~HTML,
        ---
        title: " Home "
        description: " Home page. "
        ---

        <h1>{{ site.title }}</h1>
      HTML
      "docs.md" => <<~MARKDOWN,
        ---
        title: Documentation
        description: Docs page.
        ---

        # Docs

        Welcome to {{ site.title }} {{ page.title }}.
      MARKDOWN
      "secret.md" => <<~MARKDOWN,
        ---
        title: Secret
        llms: false
        ---

        Secret body.
      MARKDOWN
      "404.html" => <<~HTML,
        ---
        title: Not Found
        ---

        <h1>Missing</h1>
      HTML
      "assets/asset.md" => <<~MARKDOWN,
        ---
        title: Asset
        ---

        Asset body.
      MARKDOWN
      "unpublished.md" => <<~MARKDOWN,
        ---
        title: Unpublished
        published: false
        ---

        Unpublished body.
      MARKDOWN
      "url-skip.md" => <<~MARKDOWN,
        ---
        title: URL Skip
        permalink: /url-skip
        ---

        URL skip body.
      MARKDOWN
      "markdown-source.html" => <<~HTML,
        ---
        title: Markdown Skip
        permalink: /markdown-output
        ---

        <p>Markdown skip body.</p>
      HTML
      "_posts/2024-01-03-hidden.md" => <<~MARKDOWN,
        ---
        title: Hidden post
        llms: false
        ---

        Hidden body.
      MARKDOWN
      "_posts/2024-01-02-newer.md" => <<~MARKDOWN,
        ---
        title: Newer post
        description: Fresh post.
        ---

        Newer {{ site.title }}.
      MARKDOWN
      "_posts/2024-01-01-older.md" => <<~MARKDOWN,
        ---
        title: Older post
        ---

        Older post body.
      MARKDOWN
    }
  end
end
