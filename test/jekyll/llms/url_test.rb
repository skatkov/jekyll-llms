# frozen_string_literal: true

require "test_helper"

class JekyllLlmsUrlTest < Minitest::Test
  cover "Jekyll::Llms::Url"

  def test_markdown_path_for_directory_and_file_urls
    assert_equal "/index.md", url_for("/").markdown_path
    assert_equal "/docs/index.md", url_for("/docs/").markdown_path
    assert_equal "/docs.md", url_for("/docs").markdown_path
    assert_equal "/docs/page.md", url_for("/docs/page.html").markdown_path
  end

  def test_absolute_url_uses_markdown_or_original_path
    url = url_for("/docs/", site: site("url" => "https://example.com/", "baseurl" => "/base/"))

    assert_equal "https://example.com/base/docs/index.md", url.absolute(markdown: true)
    assert_equal "https://example.com/base/docs/", url.absolute(markdown: false)
  end

  def test_matches_url_markdown_path_source_path_and_extglob_patterns
    url = url_for("/posts/hello", relative_path: "_posts/2024-01-01-hello.md")

    assert url.matches?("/posts/hello")
    assert url.matches?("posts/hello.md")
    assert url.matches?("_posts/**")
    assert url.matches?("/{posts/hello,missing}")
    refute url.matches?("/missing/**")
  end

  private

  def url_for(item_url, relative_path: "page.md", site: site({}))
    Jekyll::Llms::Url.new(site: site, item: item(item_url, relative_path))
  end

  def item(url, relative_path)
    Struct.new(:url, :relative_path).new(url, relative_path)
  end

  def site(config)
    defaults = {
      "url" => "https://example.com",
      "baseurl" => "",
    }
    Struct.new(:config).new(defaults.merge(config))
  end
end
