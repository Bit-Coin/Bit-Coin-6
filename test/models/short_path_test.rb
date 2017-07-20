require 'test_helper'

class ShortPathTest < ActiveSupport::TestCase

  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
  end
  
  test 'short path expires' do
    sp = ShortPath.order(created_at: :desc).first
    assert sp.active?
    Timecop.freeze(sp.active_until)
    assert sp.active?
    Timecop.freeze(sp.active_until + 1.second)
    refute sp.active?
    assert_not_equal sp.path, sp.user.short_path # issued a new one
    Timecop.return
  end

  test 'short path good for default number of days' do
    sp = ShortPath.order(created_at: :desc).first
    assert sp.active?
    assert_equal Ripple::Globals::MAX_DAYS_TO_RESPOND, sp.active_for_in_days
  end
  
  test 'short path in the morning' do
    user = User.order(created_at: :desc).first
    Timecop.freeze Time.new(2015, 3, 11, 8, 1, 0)
    assert user.short_paths.active
    Timecop.return
  end
end
