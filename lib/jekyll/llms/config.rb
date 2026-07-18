# frozen_string_literal: true

module Jekyll
  module Llms
    class Config
      DEFAULTS = {
        "markdown" => true,
        "llms_txt" => true,
        "llms_full" => false,
        "categories" => false,
        "collections" => false,
        "include" => %w[pages posts],
        "exclude" => ["/README.md", "/CHANGELOG.md"],
      }.freeze

      DEFAULT_CATEGORY_PATH_TEMPLATE = "/category/:name/"

      def self.from_site(site)
        new(DEFAULTS.merge(site.config["llms"] || {}))
      end

      def initialize(values)
        @values = values
      end

      def markdown?
        @values.fetch("markdown")
      end

      def llms_txt?
        @values.fetch("llms_txt")
      end

      def includes
        @values.fetch("include")
      end

      def excludes
        @values.fetch("exclude")
      end

      def llms_full?
        @values.fetch("llms_full")
      end

      def categories?
        @values.fetch("categories")
      end

      def collections?
        @values.fetch("collections")
      end

      def category_path_template(site)
        site.config.dig("jekyll-archives", "permalinks", "category") || DEFAULT_CATEGORY_PATH_TEMPLATE
      end

      # Soft-reads jekyll-archives.slug_mode for category :name slugification.
      # Returns nil when archives / slug_mode is absent (Jekyll default slugify mode).
      def category_slug_mode(site)
        site.config.dig("jekyll-archives", "slug_mode")
      end
    end
  end
end
