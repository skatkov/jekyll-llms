# frozen_string_literal: true

require "jekyll"
require "jekyll/llms/config"
require "jekyll/llms/entry"
require "jekyll/llms/entry_set"
require "jekyll/llms/file_writer"
require "jekyll/llms/full_index"
require "jekyll/llms/html_linker"
require "jekyll/llms/index"
require "jekyll/llms/markdown_source"
require "jekyll/llms/scope"
require "jekyll/llms/scope_enumerator"
require "jekyll/llms/site_writer"
require "jekyll/llms/url"
require "jekyll/llms/version"

module Jekyll
  module Llms
    class << self
      def write(site)
        SiteWriter.new(site).write
      end

      # Ordered callables `(site, config, entries) -> Array<Scope>` (or a single Scope).
      # Consumers register builders to contribute scoped llms.txt / llms-full.txt write targets.
      def scope_builders
        @scope_builders ||= []
      end

      # Appends a scope builder. Returns the block for optional disposal by the caller.
      # Raises ArgumentError when called without a block.
      def register_scope_builder(&block)
        raise ArgumentError, "A block is required" unless block_given?

        scope_builders << block
        block
      end

      # Clears all registered builders. Intended for tests and process-local reset.
      def reset_scope_builders!
        @scope_builders = nil
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::Llms.write(site)
end
