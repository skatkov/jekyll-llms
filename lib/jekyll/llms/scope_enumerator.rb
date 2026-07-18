# frozen_string_literal: true

module Jekyll
  module Llms
    # Builds category and collection scopes from site + config, intersecting a root Entry list.
    class ScopeEnumerator
      def initialize(site:, config:, entries:)
        @site = site
        @config = config
        @entries = entries
      end

      def scopes
        category_scopes + collection_scopes
      end

      private

      attr_reader :site, :config, :entries

      def category_scopes
        return [] unless config.categories?

        site.categories.filter_map do |name, items|
          scoped = entries.select { |entry| items.include?(entry.item) }
          next if scoped.empty?

          Scope.new(
            path_prefix: category_path(name),
            title: name,
            description: "Category: #{name}",
            entries: scoped
          )
        end
      end

      def collection_scopes
        return [] unless config.collections?

        config.includes.uniq.filter_map do |label|
          next if %w[pages posts].include?(label)

          collection = site.collections[label]
          next unless collection&.write?

          scoped = entries.select { |entry| entry.section == label }
          next if scoped.empty?

          Scope.new(
            path_prefix: "/#{label}/",
            title: label,
            description: "Collection: #{label}",
            entries: scoped
          )
        end
      end

      def category_path(name)
        slug = Utils.slugify(name, mode: config.category_slug_mode(site))
        config.category_path_template(site).sub(":name", slug)
      end
    end
  end
end
