# frozen_string_literal: true

require "test_helper"

class JekyllLlmsSiteWriterTest < Minitest::Test
  cover "Jekyll::Llms::SiteWriter"

  def test_writes_index_and_markdown_files
    build_site({}, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        description: Page description.
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/base/page.md): Page description."
      assert_equal "Page body.\n", read_output(destination, "page.md")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end

  def test_can_disable_llms_txt_while_keeping_markdown_files
    build_site({ "llms" => { "markdown" => true, "llms_txt" => false, "include" => ["pages"], "exclude" => [] } }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      refute_path_exists output_path(destination, "llms.txt")
      assert_equal "Page body.\n", read_output(destination, "page.md")
      assert_includes read_output(destination, "page.html"), %(<link rel="alternate" type="text/markdown" href="https://example.com/base/page.md">)
    end
  end

  def test_can_disable_markdown_files_while_keeping_original_index_links
    build_site({ "baseurl" => "", "llms" => { "markdown" => false, "llms_txt" => true, "include" => ["pages"], "exclude" => [] } }, {
      "_layouts/default.html" => default_layout,
      "page.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Page
        ---

        Page body.
      MARKDOWN
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Page](https://example.com/page)"
      refute_path_exists output_path(destination, "page.md")
      refute_includes read_output(destination, "page.html"), %(type="text/markdown")
    end
  end

  def test_skips_invalid_markdown_sidecar_without_stopping_other_outputs
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "valid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Valid
        render_with_liquid: false
        ---

        Valid body.
      MARKDOWN
      "invalid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Invalid
        render_with_liquid: false
        ---

        Invalid body.
      MARKDOWN
    }) do |site, destination|
      File.delete(File.join(File.dirname(destination), "invalid.md"))

      warnings = with_recorded_logs do
        Jekyll::Llms::SiteWriter.new(site).write
      end

      assert_equal "Valid body.\n", read_output(destination, "valid.md")
      refute_path_exists output_path(destination, "invalid.md")
      assert_includes read_output(destination, "valid.html"), %(href="https://example.com/base/valid.md")
      refute_includes read_output(destination, "invalid.html"), %(type="text/markdown")
      assert_includes read_output(destination, "llms.txt"), "- [Valid](https://example.com/base/valid.md)"
      assert_includes read_output(destination, "llms.txt"), "- [Invalid](https://example.com/base/invalid)"
      assert_includes warnings.fetch(0), "LLMs:"
      assert_includes warnings.fetch(0), "Skipping markdown sidecar for invalid.md: No such file or directory"
    end
  end

  def test_skips_invalid_liquid_markdown_sidecar_without_stopping_other_outputs
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "valid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Valid
        ---

        Valid body.
      MARKDOWN
      "invalid.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Invalid
        ---

        Initially valid.
      MARKDOWN
    }) do |site, destination|
      write_fixture_file(File.dirname(destination), "invalid.md", <<~MARKDOWN)
        ---
        layout: default
        title: Invalid
        ---

        {% if broken %}
      MARKDOWN

      warnings = with_recorded_logs do
        Jekyll::Llms::SiteWriter.new(site).write
      end

      assert_equal "Valid body.\n", read_output(destination, "valid.md")
      refute_path_exists output_path(destination, "invalid.md")
      assert_includes warnings.fetch(0), "LLMs:"
      assert_includes warnings.fetch(0), "Skipping markdown sidecar for invalid.md"
    end
  end

  def test_does_not_skip_destination_write_failures
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "page.md" => markdown_page
    }) do |site, destination|
      FileUtils.rm_rf(destination)
      File.write(destination, "not a directory")

      error = assert_raises(Errno::EEXIST) do
        Jekyll::Llms::SiteWriter.new(site).write
      end

      assert_includes error.message, "File exists"
    end
  end

  def test_does_not_log_destination_write_failures_as_skipped_sidecars
    build_site_without_plugin_output({
      "_layouts/default.html" => default_layout,
      "page.md" => markdown_page
    }) do |site, destination|
      FileUtils.rm_rf(destination)
      File.write(destination, "not a directory")

      warnings = with_recorded_logs do
        assert_raises(Errno::EEXIST) do
          Jekyll::Llms::SiteWriter.new(site).write
        end
      end

      assert_empty warnings
    end
  end

  def test_uses_original_links_for_html_sources
    build_site({}, {
      "_layouts/default.html" => default_layout,
      "index.html" => <<~HTML,
        ---
        layout: default
        title: Home
        description: Home page.
        ---

        <h1>Home</h1>
      HTML
    }) do |_site, destination|
      assert_includes read_output(destination, "llms.txt"), "- [Home](https://example.com/base/): Home page."
      refute_path_exists output_path(destination, "index.md")
      refute_includes read_output(destination, "index.html"), %(type="text/markdown")
    end
  end

  def test_excludes_project_docs_by_default
    build_site({ "llms" => :absent }, {
      "_layouts/default.html" => default_layout,
      "README.md" => <<~MARKDOWN,
        ---
        layout: default
        title: README
        description: Should not be published to llms.txt.
        ---

        Secret-adjacent setup notes.
      MARKDOWN
      "CHANGELOG.md" => <<~MARKDOWN,
        ---
        layout: default
        title: Changelog
        description: Release notes should not be published to llms.txt.
        ---

        Internal release notes.
      MARKDOWN
    }) do |_site, destination|
      refute_includes read_output(destination, "llms.txt"), "README"
      refute_includes read_output(destination, "llms.txt"), "Changelog"
      refute_path_exists output_path(destination, "README.md")
      refute_path_exists output_path(destination, "CHANGELOG.md")
    end
  end

  private

  def default_layout
    "<html><head><title>{{ page.title }}</title></head><body>{{ content }}</body></html>\n"
  end

  def build_site_without_plugin_output(files)
    build_site({ "llms" => { "markdown" => false, "llms_txt" => false, "include" => ["pages"], "exclude" => [] } }, files) do |site, destination|
      site.config["llms"] = { "markdown" => true, "llms_txt" => true, "include" => ["pages"], "exclude" => [] }
      yield site, destination
    end
  end

  def markdown_page
    <<~MARKDOWN
      ---
      layout: default
      title: Page
      render_with_liquid: false
      ---

      Page body.
    MARKDOWN
  end

  def with_recorded_logs
    writer = Struct.new(:warnings, :level) do
      def warn(message)
        warnings << message
      end

      def error(_message)
      end
    end.new([])
    original_writer = Jekyll.logger.writer
    original_level = Jekyll.logger.level
    Jekyll.logger = writer
    Jekyll.logger.log_level = :warn
    yield
    writer.warnings
  ensure
    Jekyll.logger = original_writer
    Jekyll.logger.log_level = original_level
  end
end
