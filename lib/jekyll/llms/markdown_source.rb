# frozen_string_literal: true

module Jekyll
  module Llms
    class MarkdownSource
      def initialize(site:, item:)
        @site = site
        @item = item
      end

      def content
        render_liquid(strip_frontmatter(read_file))
      end

      private

      attr_reader :site, :item

      def path
        site.in_source_dir(item.relative_path)
      end

      def read_file
        File.read(path)
      end

      def strip_frontmatter(content)
        content =~ Document::YAML_FRONT_MATTER_REGEXP
        Regexp.last_match.post_match
      end

      def render_liquid(content)
        return content if item["render_with_liquid"] == false

        Renderer.new(site, nil).render_liquid(content, payload, nil, path)
      end

      def payload
        site.site_payload.tap do |payload|
          payload["page"] = item
        end
      end

    end
  end
end
