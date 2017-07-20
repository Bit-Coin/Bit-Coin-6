require 'test_helper'

class ScoreTest < ActiveSupport::TestCase
  before do
    AcmeHelper.generate_acme_company_data
    load 'db/script/one_time/set_up_fannie_mae.rb'
  end

  it 'scopes for parent characteristic' do
    assert_equal 579, Score.all.count
    assert_equal 420, Score.for_parent_characteristic(1).count
  end
end
