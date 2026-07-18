# frozen_string_literal: true

require "test_helper"

class JekyllLlmsConfigTest < Minitest::Test
  cover "Jekyll::Llms::Config"

  def test_uses_defaults_when_site_config_is_absent
    config = Jekyll::Llms::Config.from_site(site({}))

    assert_predicate config, :markdown?
    assert_predicate config, :llms_txt?
    assert_equal %w[pages posts], config.includes
    assert_equal ["/README.md", "/CHANGELOG.md"], config.excludes
  end

  def test_uses_defaults_when_site_config_is_nil
    config = Jekyll::Llms::Config.from_site(site("llms" => nil))

    assert_predicate config, :markdown?
    assert_predicate config, :llms_txt?
    assert_equal %w[pages posts], config.includes
    assert_equal ["/README.md", "/CHANGELOG.md"], config.excludes
  end

  def test_merges_user_values_over_defaults
    config = Jekyll::Llms::Config.from_site(site(
      "llms" => {
        "markdown" => false,
        "llms_txt" => false,
        "include" => ["pages"],
        "exclude" => ["/skip/**"],
      }
    ))

    refute_predicate config, :markdown?
    refute_predicate config, :llms_txt?
    assert_equal ["pages"], config.includes
    assert_equal ["/skip/**"], config.excludes
  end

  def test_new_flags_default_false
    config = Jekyll::Llms::Config.from_site(site({}))

    refute_predicate config, :llms_full?
    refute_predicate config, :categories?
    refute_predicate config, :collections?
  end

  def test_merges_new_flags_when_true
    config = Jekyll::Llms::Config.from_site(site(
      "llms" => {
        "llms_full" => true,
        "categories" => true,
        "collections" => true,
      }
    ))

    assert_predicate config, :llms_full?
    assert_predicate config, :categories?
    assert_predicate config, :collections?
  end

  def test_category_path_template_defaults_without_archives
    config = Jekyll::Llms::Config.from_site(site({}))

    assert_equal "/category/:name/", config.category_path_template(site({}))
  end

  def test_category_path_template_uses_archives_permalink_when_present
    config = Jekyll::Llms::Config.from_site(site({}))
    archives_site = site(
      "jekyll-archives" => {
        "permalinks" => {
          "category" => "/topics/:name/",
        },
      }
    )

    assert_equal "/topics/:name/", config.category_path_template(archives_site)
  end

  # Soft-reads jekyll-archives.slug_mode when present; nil when archives / slug_mode absent.
  def test_category_slug_mode_defaults_without_archives
    config = Jekyll::Llms::Config.from_site(site({}))

    assert_nil config.category_slug_mode(site({}))
  end

  def test_category_slug_mode_uses_archives_value_when_present
    config = Jekyll::Llms::Config.from_site(site({}))
    archives_site = site("jekyll-archives" => { "slug_mode" => "ascii" })

    assert_equal "ascii", config.category_slug_mode(archives_site)
  end

  private

  def site(config)
    Struct.new(:config).new(config)
  end
end
