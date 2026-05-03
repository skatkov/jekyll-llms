# frozen_string_literal: true

module Jekyll
  module Llms
    class Config
      DEFAULTS = {
        "markdown" => true,
        "llms_txt" => true,
        "include" => %w[pages posts],
        "exclude" => [],
      }.freeze

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
    end
  end
end
