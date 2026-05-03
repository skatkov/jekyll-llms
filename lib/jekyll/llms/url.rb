# frozen_string_literal: true

module Jekyll
  module Llms
    class Url
      MATCH_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB

      def initialize(site:, item:)
        @site = site
        @item = item
      end

      def absolute(markdown:)
        "#{prefix}#{path(markdown: markdown)}"
      end

      def markdown_path
        url = item.url
        return "#{url}index.md" if url.end_with?("/")

        File.join(File.dirname(url), "#{File.basename(url, ".*")}.md")
      end

      def matches?(pattern)
        candidates.any? do |candidate|
          glob_match?(pattern, candidate)
        end
      end

      private

      attr_reader :site, :item

      def path(markdown:)
        markdown ? markdown_path : item.url
      end

      def prefix
        url, baseurl = site.config.fetch_values("url", "baseurl")

        "#{url.delete_suffix("/")}#{baseurl.delete_suffix("/")}"
      end

      def candidates
        [item.url, markdown_path, relative_source_path]
      end

      def relative_source_path
        "/#{item.relative_path}"
      end

      def glob_match?(pattern, candidate)
        File.fnmatch?(pattern.delete_prefix("/"), candidate.delete_prefix("/"), MATCH_FLAGS)
      end
    end
  end
end
