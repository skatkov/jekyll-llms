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
        write_full if config.llms_full?
        write_scopes(markdown_entries)
        write_html_links(markdown_entries)
      end

      private

      attr_reader :site, :config, :entries, :files

      def write_index(markdown_entries, scope: nil, path: "llms.txt")
        index = if scope
                  Index.new(
                    entries: scope.entries,
                    url_for: index_url(markdown_entries),
                    title: scope.title,
                    description: scope.description
                  )
                else
                  Index.new(site: site, entries: entries, url_for: index_url(markdown_entries))
                end
        files.write(path, index.content)
      end

      def write_full(scope: nil, path: "llms-full.txt")
        entry_list = scope ? scope.entries : entries
        title = scope ? scope.title : site.config.fetch("title", "Jekyll Site")
        pairs = full_entry_pairs(entry_list)
        files.write(path, FullIndex.new(title: title, entries: pairs).content)
      end

      def write_scopes(markdown_entries)
        scopes = (built_in_scopes + extra_scopes).reject { |scope| scope.entries.empty? }
        ensure_unique_path_prefixes!(scopes)

        scopes.each do |scope|
          prefix = normalized_path_prefix(scope.path_prefix)
          write_index(markdown_entries, scope: scope, path: "#{prefix}llms.txt") if config.llms_txt?
          write_full(scope: scope, path: "#{prefix}llms-full.txt") if config.llms_full?
        end
      end

      def built_in_scopes
        ScopeEnumerator.new(site: site, config: config, entries: entries).scopes
      end

      def extra_scopes
        Llms.scope_builders.flat_map { |builder| Array(builder.call(site, config, entries)) }
      end

      def ensure_unique_path_prefixes!(scopes)
        scopes.group_by { |scope| normalized_path_prefix(scope.path_prefix) }.each do |prefix, group|
          raise ArgumentError, "Duplicate LLMs scope path_prefix: #{prefix}" if group.size > 1
        end
      end

      def normalized_path_prefix(prefix)
        segments = prefix.split("/").reject(&:empty?)
        if segments.empty? || segments.any? { |segment| segment == "." || segment == ".." }
          raise ArgumentError, "Invalid LLMs scope path_prefix: #{prefix.inspect}"
        end

        "/#{segments.join("/")}/"
      end

      def full_entry_pairs(entry_list)
        entry_list.select(&:markdown_source?).map do |entry|
          [entry.title, markdown_content(entry)]
        end
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
