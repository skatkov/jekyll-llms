# frozen_string_literal: true

module Jekyll
  module Llms
    # Renders a concatenated Markdown corpus for llms-full.txt.
    # +entries+ is an Array of +[title, body]+ pairs; nil/empty bodies are omitted.
    class FullIndex
      def initialize(title:, entries:)
        @title = title
        @entries = entries
      end

      def content
        parts = ["# #{@title}\n"]
        @entries.each do |entry_title, body|
          next if body.nil? || body.empty?

          parts << "\n## #{entry_title}\n\n#{body}"
        end
        parts.join
      end
    end
  end
end
