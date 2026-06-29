# frozen_string_literal: true

module Jekyll
  module Llms
    class SiteWriter
      def initialize(site)
        @site = site
        @config = Config.from_site(site)
        @entries = EntrySet.new(site: site, config: config).entries
        @files = FileWriter.new(site.dest)
      end

      def write
        markdown_entries = config.markdown? ? write_markdown : []

        write_index(markdown_entries) if config.llms_txt?
        write_html_links(markdown_entries)
      end

      private

      attr_reader :site, :config, :entries, :files

      def write_index(markdown_entries)
        files.write("llms.txt", Index.new(site: site, entries: entries, url_for: index_url(markdown_entries)).content)
      end

      def index_url(markdown_entries)
        lambda do |entry|
          entry.url.absolute(markdown: markdown_entries.include?(entry))
        end
      end

      def write_markdown
        markdown_entries.filter_map do |entry|
          content = markdown_content(entry)
          next unless content

          files.write(entry.url.markdown_path, content)
          entry
        end
      end

      def markdown_content(entry)
        MarkdownSource.new(site: site, item: entry.item).content
      rescue Liquid::Error, SystemCallError => error
        Jekyll.logger.warn("LLMs:", "Skipping markdown sidecar for #{entry.item.relative_path}: #{error}")
        nil
      end

      def write_html_links(markdown_entries)
        HtmlLinker.new(site: site, entries: markdown_entries).write
      end

      def markdown_entries
        entries.select(&:markdown_source?)
      end
    end
  end
end
