require 'test_helper'

class RippleTimeTest < ActiveSupport::TestCase
  test 'beginning of week just prior to switchover' do 
    t = Time.new(2015,1,27,8,33,59, "-05:00") # one second prior to start of new week
    rt = Ripple::Time.new(t)
    assert_equal Time.new(2015,1,20,8,34,0, "-05:00"), rt.beginning_of_week
  end

  test 'beginning of week just prior to midnight the day before' do 
    t = Time.new(2015,1,26,23,59,59, "-05:00")
    rt = Ripple::Time.new(t)
    assert_equal Time.new(2015,1,20,8,34,0, "-05:00"), rt.beginning_of_week
  end

  test 'beginning of week just after switchover' do 
    t = Time.new(2015,1,27,8,34,01, "-05:00")
    rt = Ripple::Time.new(t)
    assert_equal Time.new(2015,1,27,8,34,0, "-05:00"), rt.beginning_of_week
  end

  test 'round down' do
    t = Time.new(2015,2,10,8,34,01, "-05:00")
    rt = Ripple::Time.new(t)
    assert_equal Time.new(2015,2,10,8,34,0, "-05:00"), rt.round
  end

  test 'round up' do
    t = Time.new(2015,2,13,20,34,01, "-05:00")
    rt = Ripple::Time.new(t)
    assert_equal Time.new(2015,2,17,8,34,0, "-05:00"), rt.round
  end
end
