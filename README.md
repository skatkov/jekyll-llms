# jekyll-llms

Jekyll plugin that produces LLM-friendly formats alongside a regular website.

Namely: `llms.txt`, Markdown sidecars, and HTML alternate links to sidecars.

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
- `*.md`: source-body sidecars for included entries.
- HTML `<link rel="alternate" type="text/markdown" href="...">` tags pointing to sidecars.

Sidecars are source bodies, not HTML-to-Markdown conversions. Front matter is removed. Liquid is rendered unless `render_with_liquid: false` is set.

## Configuration

```yaml
llms:
  markdown: true
  llms_txt: true
  include:
    - pages
    - posts
  exclude:
    - /404.html
    - /assets/**
```

- `markdown`: generate sidecars, link `llms.txt` to sidecars, and add HTML alternate links. Default: `true`.
- `llms_txt`: generate `/llms.txt`. Default: `true`.
- `include`: `pages`, `posts`, and output collection names. Default: `[pages, posts]`.
- `exclude`: URL, Markdown path, or source path globs. Default: `[]`.

Per-entry opt-out:

```yaml
llms: false
```

## License

MIT. See `LICENSE.txt`.
