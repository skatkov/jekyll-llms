# frozen_string_literal: true

require "fileutils"

module Jekyll
  module Llms
    class FileWriter
      def initialize(destination)
        @destination = destination
      end

      def write(path, content)
        full_path = File.join(destination, path)
        FileUtils.mkdir_p(File.dirname(full_path))
        File.write(full_path, content)
      end

      private

      attr_reader :destination
    end
  end
end
