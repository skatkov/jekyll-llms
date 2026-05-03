# frozen_string_literal: true

require "test_helper"

class JekyllLlmsHtmlLinkerTest < Minitest::Test
  cover "Jekyll::Llms::HtmlLinker"

  def test_links_html_output_to_markdown_counterpart
    Dir.mktmpdir("jekyll-llms-html-linker") do |destination|
      write_fixture_file(destination, "page.html", "<html><head><title>Page</title></head><body></body></html>")
      site = site(destination)

      Jekyll::Llms::HtmlLinker.new(site: site, entries: [entry(site: site, path: "page.html", url: "/page.html")]).write

      assert_equal <<~HTML.chomp, File.read(File.join(destination, "page.html"))
        <html><head><title>Page</title><link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">
        </head><body></body></html>
      HTML
    end
  end

  def test_skips_non_html_output
    Dir.mktmpdir("jekyll-llms-html-linker") do |destination|
      write_fixture_file(destination, "feed.xml", "<feed><head></head></feed>")
      site = site(destination)

      Jekyll::Llms::HtmlLinker.new(site: site, entries: [entry(site: site, path: "feed.xml", url: "/feed.xml")]).write

      assert_equal "<feed><head></head></feed>", File.read(File.join(destination, "feed.xml"))
    end
  end

  def test_skips_missing_html_output
    Dir.mktmpdir("jekyll-llms-html-linker") do |destination|
      site = site(destination)

      Jekyll::Llms::HtmlLinker.new(site: site, entries: [entry(site: site, path: "missing.html", url: "/missing.html")]).write

      refute_path_exists File.join(destination, "missing.html")
    end
  end

  def test_leaves_html_without_head_end_tag_unchanged
    Dir.mktmpdir("jekyll-llms-html-linker") do |destination|
      write_fixture_file(destination, "page.html", "<html><body></body></html>")
      site = site(destination)

      Jekyll::Llms::HtmlLinker.new(site: site, entries: [entry(site: site, path: "page.html", url: "/page.html")]).write

      assert_equal "<html><body></body></html>", File.read(File.join(destination, "page.html"))
    end
  end

  private

  def site(destination)
    Struct.new(:dest, :config).new(destination, {
      "url" => "https://example.com/",
      "baseurl" => "/base/",
    })
  end

  def entry(site:, path:, url:)
    item = item(path: path, url: url)

    Jekyll::Llms::Entry.new(site: site, item: item, section: "pages")
  end

  def item(path:, url:)
    Class.new do
      attr_reader :url, :relative_path, :data, :name

      def initialize(path, url)
        @path = path
        @url = url
        @relative_path = path
        @data = {}
        @name = path
      end

      def destination(destination)
        File.join(destination, @path)
      end
    end.new(path, url)
  end
end
