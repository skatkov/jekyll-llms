# frozen_string_literal: true

module Jekyll
  module Llms
    # One scoped write target: path prefix plus filtered entries and display metadata.
    class Scope
      attr_reader :path_prefix, :title, :description, :entries

      def initialize(path_prefix:, title:, description:, entries:)
        @path_prefix = path_prefix
        @title = title
        @description = description
        @entries = entries
      end
    end
  end
end
