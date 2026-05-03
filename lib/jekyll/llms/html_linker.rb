# frozen_string_literal: true

module Jekyll
  module Llms
    class HtmlLinker
      def initialize(site:, entries:)
        @site = site
        @entries = entries
      end

      def write
        entries.each do |entry|
          write_link(entry)
        end
      end

      private

      attr_reader :site, :entries

      def write_link(entry)
        path = entry.item.destination(site.dest)
        return unless path.end_with?(".html")
        return unless File.file?(path)

        content = File.read(path)
        File.write(path, content.sub("</head>", "#{link(entry)}\n</head>"))
      end

      def link(entry)
        %(<link rel="alternate" type="text/markdown" href="#{entry.url.absolute(markdown: true)}">)
      end
    end
  end
end
