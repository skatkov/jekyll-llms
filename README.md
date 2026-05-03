# jekyll-llms

Generate LLM-friendly files for Jekyll sites.

## Installation

Add the gem to your Jekyll site:

```ruby
group :jekyll_plugins do
  gem "jekyll-llms"
end
```

Enable the plugin in `_config.yml`:

```yaml
plugins:
  - jekyll-llms

llms:
  markdown: true
  llms_txt: true
```

## What It Generates

- `llms.txt`: a Markdown index of included pages, posts, and collection documents.
- `.md` sidecars: source-content mirrors for included pages, posts, and collection documents.

The plugin does not convert HTML to Markdown. It removes front matter, renders Liquid in the source body, and writes the result as-is.

When Markdown sidecars are enabled, `llms.txt` links to the generated `.md` files instead of the original site URLs. This includes HTML pages: `/about.html` is linked as `/about.md`, and `/docs/` is linked as `/docs/index.md`.

## Configuration

All options live under `llms` in `_config.yml`:

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

- `markdown`: generate `.md` sidecars and link `llms.txt` entries to them. Set to `false` to skip sidecars and link to original URLs.
- `llms_txt`: generate `llms.txt`. Set to `false` if you only want sidecars.
- `include`: sections to include. Supports `pages`, `posts`, and output collections by collection name.
- `exclude`: URL, generated Markdown path, or source path patterns to skip. Glob patterns such as `/assets/**` and `/{404.html,feed.xml}` are supported.

Use front matter to exclude a single page or document:

```yaml
llms: false
```

## License

MIT. See `LICENSE.txt`.
