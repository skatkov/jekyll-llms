# frozen_string_literal: true

module Jekyll
  module Llms
    class EntrySet
      def initialize(site:, config:)
        @site = site
        @config = config
      end

      def entries
        config.includes.flat_map do |section|
          section_entries(section)
        end.select do |entry|
          entry.enabled? && !entry.excluded_by?(config.excludes)
        end.uniq do |entry|
          entry.item.url
        end
      end

      private

      attr_reader :site, :config

      def section_entries(section)
        items_for(section).map do |item|
          Entry.new(site: site, item: item, section: section)
        end
      end

      def items_for(section)
        case section
        when "pages"
          site.pages
        when "posts"
          site.posts.docs.sort { |a, b| b <=> a }
        else
          collection_items(section)
        end
      end

      def collection_items(section)
        collection = site.collections[section]
        return [] unless collection&.write?

        collection.docs
      end
    end
  end
end
