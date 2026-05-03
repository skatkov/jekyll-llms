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
        write_index if config.llms_txt?
        write_markdown if config.markdown?
      end

      private

      attr_reader :site, :config, :entries, :files

      def write_index
        files.write("llms.txt", Index.new(site: site, entries: entries, markdown: config.markdown?).content)
      end

      def write_markdown
        entries.each do |entry|
          files.write(entry.url.markdown_path, MarkdownSource.new(site: site, item: entry.item).content)
        end
      end
    end
  end
end
