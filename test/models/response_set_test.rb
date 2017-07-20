require 'test_helper'

class ResponseSetTest < ActiveSupport::TestCase
  it 'returns the hash sorted and cast' do
    target = HashWithIndifferentAccess.new({
      never: 1,
      rarely: 2,
      sometimes: 3,
      often: 4,
      always: 5
    })
    source = ResponseSet.first.ordered_values
    assert_equal HashWithIndifferentAccess, source.class
    assert_equal target, source
  end
end
