# frozen_string_literal: true

require "test_helper"

class JekyllLlmsFileWriterTest < Minitest::Test
  cover "Jekyll::Llms::FileWriter"

  def setup
    FileUtils.rm_rf("nested")
  end

  def teardown
    FileUtils.rm_rf("nested")
    super
  end

  def test_writes_nested_files_under_destination
    Dir.mktmpdir("jekyll-llms-file-writer") do |destination|
      Jekyll::Llms::FileWriter.new(destination).write("nested/file.md", "Body\n")

      assert_equal "Body\n", File.read(File.join(destination, "nested/file.md"))
    end
  end
end
