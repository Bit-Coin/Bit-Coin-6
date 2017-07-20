require 'test_helper'

class CharactersticTest < ActiveSupport::TestCase
  test 'top_level scope' do
    top_levels = Characteristic.top_level
    assert top_levels.include?(Characteristic.ripple_effect_score)
    assert_equal 2, top_levels.count
  end

  test 'components' do
    assert_equal 5, Characteristic.ripple_effect_score.components.count
  end
end
