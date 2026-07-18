# jekyll-llms

Jekyll plugin that produces LLM-friendly formats alongside a regular website.

Namely: `llms.txt`, optional `llms-full.txt`, Markdown sidecars, and HTML alternate links to sidecars.

## Installation

Add to `Gemfile` and run `bundle install`
```ruby
group :jekyll_plugins do
  gem "jekyll-llms"
end
```

Add to `_config` file:

```yaml
plugins:
  - jekyll-llms
```


## Output

- `/llms.txt`: Markdown index of included entries.
- `/llms-full.txt`: concatenated Markdown corpus of included entries (optional).
- Per-category and per-collection `llms.txt` / `llms-full.txt` beside those scopes (optional).
- `*.md`: source-body sidecars for included Markdown-source entries.
- HTML `<link rel="alternate" type="text/markdown" href="...">` tags pointing to sidecars.

Sidecars are source bodies, not HTML-to-Markdown conversions. Front matter is removed. Liquid is rendered unless `render_with_liquid: false` is set. HTML-source entries stay linked by their original URLs. HTML-only entries appear in indexes but are omitted from `llms-full.txt`.

## Configuration

```yaml
llms:
  markdown: true
  llms_txt: true
  llms_full: false
  categories: false
  collections: false
  include:
    - pages
    - posts
  exclude:
    - /README.md
    - /CHANGELOG.md
    - /404.html
    - /assets/**
```

- `markdown`: generate sidecars for Markdown sources, link `llms.txt` to those sidecars, and add HTML alternate links. Default: `true`.
- `llms_txt`: generate `llms.txt` at the site root and for each active scope. Default: `true`.
- `llms_full`: generate `llms-full.txt` at the site root and for each active scope. Default: `false`.
- `categories`: include a scope for each non-empty category after include/exclude filtering (artifact types still controlled by `llms_txt` / `llms_full`). Default: `false`.
- `collections`: include a scope under `/{label}/` for each included writeable collection (not `pages`/`posts`). Default: `false`.
- `include`: `pages`, `posts`, and output collection names. Default: `[pages, posts]`.
- `exclude`: URL, Markdown path, or source path globs. Default: `[/README.md, /CHANGELOG.md]`.

`categories`, `collections`, and `register_scope_builder` decide which scopes exist. `llms_txt`, `llms_full`, and `markdown` decide what is generated for the root and for those scopes. For example, `llms_txt: false` with `llms_full: true` and `categories: true` writes only full indexes (root and per-category).

Per-entry opt-out:

```yaml
llms: false
```

### Category Paths

Category files land under the category archive path. When [jekyll-archives](https://github.com/jekyll/jekyll-archives) configures `permalinks.category`, that template is used. Otherwise the default is `/category/:name/`, matching jekyll-archives' stock category permalink. When archives configures `slug_mode`, that mode is used when slugifying `:name`. The gem does not require jekyll-archives; it just plays nice with it if it is present.

### Custom Scopes

Sites can register additional scoped write targets (e.g. tags, authors, custom archives or aggregations).

For example, if you had "tags" on posts, and URLs like `/tags/foo/` that showed a list of all posts tagged with `foo`, you could register a scope builder like this:

```ruby
# _plugins/llms_tag_scopes.rb
Jekyll::Llms.register_scope_builder do |site, _config, entries|
  template = site.config.dig("jekyll-archives", "permalinks", "tag") || "/tags/:name/"
  site.tags.filter_map do |name, items|
    scoped = entries.select { |entry| items.include?(entry.item) }
    next if scoped.empty?

    Jekyll::Llms::Scope.new(
      path_prefix: template.sub(":name", Jekyll::Utils.slugify(name)),
      title: name,
      description: "Tag: #{name}",
      entries: scoped
    )
  end
end
```

Then, `/tags/foo/llms.txt` would show all the posts tagged with `foo`.

## License

MIT. See `LICENSE.txt`.
