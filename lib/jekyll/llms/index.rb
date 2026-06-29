# frozen_string_literal: true

module Jekyll
  module Llms
    class Index
      def initialize(site:, entries:, url_for:)
        @site = site
        @entries = entries
        @url_for = url_for
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
        site.config.fetch("title", "Jekyll Site")
      end

      def description
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
