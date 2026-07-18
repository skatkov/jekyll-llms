# frozen_string_literal: true

module Jekyll
  module Llms
    class Index
      # Optional title:/description: override site config for scoped indexes.
      # +site+ may be omitted when both title and description overrides are provided.
      def initialize(entries:, url_for:, site: nil, title: nil, description: nil)
        @site = site
        @entries = entries
        @url_for = url_for
        @title_override = title
        @description_override = description
      end

      def content
        content = "# #{title}\n\n"
        content << "> #{description}\n" unless description.empty?

        entries.group_by(&:section).each do |section, section_entries|
          content << "\n## #{section_title(section)}\n\n"
          section_entries.each do |entry|
            content << "#{entry_line(entry)}\n"
          end
        end

        content
      end

      private

      attr_reader :site, :entries, :url_for

      def title
        return @title_override unless @title_override.nil?

        site.config.fetch("title", "Jekyll Site")
      end

      def description
        return @description_override unless @description_override.nil?

        site.config.fetch("description", "").strip
      end

      def entry_line(entry)
        line = "- [#{entry.title}](#{url_for.call(entry)})"
        entry.description.empty? ? line : "#{line}: #{entry.description}"
      end

      def section_title(section)
        section.split(/[_-]/).map(&:capitalize).join(" ")
      end
    end
  end
end
