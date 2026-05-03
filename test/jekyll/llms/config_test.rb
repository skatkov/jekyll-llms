# frozen_string_literal: true

require "test_helper"

class JekyllLlmsConfigTest < Minitest::Test
  cover "Jekyll::Llms::Config"

  def test_uses_defaults_when_site_config_is_absent
    config = Jekyll::Llms::Config.from_site(site({}))

    assert_predicate config, :markdown?
    assert_predicate config, :llms_txt?
    assert_equal %w[pages posts], config.includes
    assert_equal [], config.excludes
  end

  def test_uses_defaults_when_site_config_is_nil
    config = Jekyll::Llms::Config.from_site(site("llms" => nil))

    assert_predicate config, :markdown?
    assert_predicate config, :llms_txt?
    assert_equal %w[pages posts], config.includes
    assert_equal [], config.excludes
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

  private

  def site(config)
    Struct.new(:config).new(config)
  end
end
