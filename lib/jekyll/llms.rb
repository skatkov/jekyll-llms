# frozen_string_literal: true

require "jekyll"
require "jekyll/llms/config"
require "jekyll/llms/entry"
require "jekyll/llms/entry_set"
require "jekyll/llms/file_writer"
require "jekyll/llms/html_linker"
require "jekyll/llms/index"
require "jekyll/llms/markdown_source"
require "jekyll/llms/site_writer"
require "jekyll/llms/url"
require "jekyll/llms/version"

module Jekyll
  module Llms
    class << self
      def write(site)
        SiteWriter.new(site).write
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::Llms.write(site)
end
