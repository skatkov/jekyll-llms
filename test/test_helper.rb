# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/test/"
  minimum_coverage 100
  track_files "lib/**/*.rb"
end

original_verbose = $VERBOSE
$VERBOSE = nil
load File.expand_path("../lib/jekyll/llms/version.rb", __dir__)
$VERBOSE = original_verbose

require "fileutils"
require "minitest/autorun"
require "mutant/minitest/coverage"
require "tmpdir"

require_relative "support/mutant_setup"

Jekyll.logger.log_level = :error

class Minitest::Test
  private

  def build_site(config = {}, files = {})
    Dir.mktmpdir("jekyll-llms-test") do |source|
      destination = File.join(source, "_site")
      files.each do |path, content|
        write_fixture_file(source, path, content)
      end

      site_config = default_config(source, destination).merge(config)
      site_config.delete_if { |_key, value| value == :absent }

      site = Jekyll::Site.new(Jekyll.configuration(site_config))
      site.process

      yield site, destination
    end
  end

  def default_config(source, destination)
    {
      "source" => source,
      "destination" => destination,
      "title" => "Fixture Site",
      "description" => " Fixture description. ",
      "url" => "https://example.com/",
      "baseurl" => "/base/",
      "permalink" => "/blog/:title",
      "quiet" => true,
      "llms" => {
        "markdown" => true,
        "llms_txt" => true,
        "include" => %w[pages posts],
        "exclude" => ["/{404.html,url-skip,markdown-output.md}", "/assets/**"],
      },
    }
  end

  def write_fixture_file(source, path, content)
    full_path = File.join(source, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def read_output(destination, path)
    File.read(File.join(destination, path))
  end

  def output_path(destination, path)
    File.join(destination, path)
  end
end
