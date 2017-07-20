require 'test_helper'

class UserTest < ActiveSupport::TestCase
  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans
    AcmeHelper.generate_acme_surveys
  end
  
  test 'password validations' do
    u = User.first
    u.password = 'bad'
    refute u.valid?
    u.password = 'shoRt1'
    refute u.valid?
    u.password = 'longButNotComplex'
    refute u.valid?
    u.password = 'longAndComplex123'
    assert u.valid?
    u.password = Security::DEMO_PASSWORD
    assert u.valid?
  end

  test 'short path gets set on create' do 
    assert_equal 6, User.first.short_path.length
  end

  test 'free email provider list loads' do
    assert Ripple::FreeEmailProviders.domains.include?('gmail.com')
  end

  test 'User#short_path finds or creates' do
    ShortPath.destroy_all
    assert_equal [], User.first.short_paths # really gone
    assert_equal 6, User.first.short_path.length # creates it on the fly
    assert_equal 1, ShortPath.count # it's the only one now
  end

  test '#find_first_by_auth_conditions' do
    orig_user, dup_user = AcmeHelper.duplicate_acme_user_in_ripple_company
    assert dup_user.id > orig_user.id, "Dup user id should be higher than orig user"
    assert_equal dup_user, User.find_first_by_auth_conditions({email: orig_user.email})
  end

  test 'does not mark deleted users active' do
    u = User.first
    u.delete!
    u.well_look_whos_here!
    assert_equal 'deleted', u.reload.state
  end

  test "cannot have nil company as rippler" do
    user = User.first
    assert user.valid?, "Invalid user"
    user.type = 'rippler'
    user.company = nil
    refute user.valid?, "Shouldn't be valid"
    user.type = 'prospect'
    user.pending_company_name = ''
    refute user.valid?, "Shouldn't be valid"
    user.pending_company_name = Faker::Company.name
    assert user.valid?, "Oddly invalid"
  end

  test 'user.bounce!' do
    bouncingemail = 'demo+bademail@ripplecrew.com'

    receiver = User.first
    sp = receiver.survey_plans.build_from_params(receiver: receiver, email: bouncingemail, state: 'active')
    sp.save!

    bouncer = User.find_by_email(bouncingemail)
    assert bouncer.state == 'invited', "Bounce user didn't get invited state"
    assert bouncer.type == 'unregistered_giver'
    bouncer.save!

    bouncer.bounce!
    assert bouncer.state == 'bouncing', "Bounce user didn't set self to bouncing status"
    bouncer.save!

    assert bouncer.do_not_contact?

    states = SurveyPlan.for_giver(bouncer).pluck(:state).uniq
    assert states.size == 1, "Plans for bounced user have states: #{states.to_s}"
    assert states[0] == 'bounced', "Plan for bounced user doesn't have bounced status"
  end

  test 'user.unsubscribe!' do
    unsubemail = 'demo+unsubscriber@ripplecrew.com'

    receiver = User.first
    sp = SurveyPlan.build_from_params(receiver: receiver, email: unsubemail, state: 'active')
    sp.save!

    unsubber = User.find_by_email(unsubemail)
    assert unsubber.state == 'invited'
    assert unsubber.type == 'unregistered_giver'
    unsubber.save!

    unsubber.unsubscribe!
    assert unsubber.state == 'unsubscribed'
    assert unsubber.type == 'unregistered_giver'
    assert unsubber.unsubscribed_at
    assert unsubber.do_not_contact?
    unsubber.save!

    states = unsubber.giver_survey_plans.pluck(:state).uniq
    assert states.size == 1, states.to_s
    assert states[0] == 'unsubscribed'
  end

  test 'ripplers can never appear unresponsive' do
    r = User.rippler.first
    r.surveys.destroy_all # remove any closed surveys
    Timecop.freeze(Time.now + 57.days)
    refute r.appears_unresponsive?
  end

  test 'appears_unresponsive? for unregistered_giver' do
    AcmeHelper.generate_acme_unregistered_givers(1)
    Timecop.freeze(Time.now + 57.days)
    ug = User.unregistered_givers.first
    assert ug.appears_unresponsive?, "UG should appear unresponsive"
  end

  test 'promoted_to_rippler?' do
    u = User.first
    u.type = 'unregistered_giver'
    refute u.promoted_to_rippler?
    u.save!
    u.type = 'rippler'
    assert u.promoted_to_rippler?
  end

  test 'need_reminding' do
    Timecop.freeze(Time.new(2015, 4, 10, 8, 34, 0))
    AcmeHelper.generate_acme_surveys
    assert_equal 2, User.need_reminding.count
    User.update_all(last_reminded_at: Time.now - 1.day)
    assert_equal 0, User.need_reminding.count
  end

  test 'recently_reminded' do
    Timecop.freeze(Date.parse("Monday")) # so we don't fail if the test is run on Sat/Sun
    assert_equal 0, User.recently_reminded.count
    User.last.update_attributes(last_reminded_at: '2015-04-07 8:34') # tues
    Timecop.freeze(Time.new(2015, 4, 10, 8, 34, 0)) # fri at appointed time
    assert_equal 0, User.recently_reminded.count
    Timecop.freeze(Time.new(2015, 4, 10, 7, 59, 0)) # fri prior to appointed time
    assert_equal 1, User.recently_reminded.count
    Timecop.freeze(Time.new(2015, 4, 13, 8, 0, 0))
    assert_equal 0, User.recently_reminded.count # should hold true on business
      # days later as well

    User.last.update_attributes(last_reminded_at: '2015-04-03 8:34') # friday
    Timecop.freeze(Time.new(2015, 4, 7, 8, 34, 0)) # tues at appointed time
    assert_equal 0, User.recently_reminded.count    
    Timecop.freeze(Time.new(2015, 4, 7, 7, 59, 0)) # tues prior to appointed time
    assert_equal 1, User.recently_reminded.count

    Timecop.freeze(Time.new(2015, 4, 11, 8, 34)) # Saturday
    assert_equal User.count, User.recently_reminded.count
  end

  test '#relationship_type_options' do
    assert_equal [nil, 'Colleague','Peer','Manager','Direct Report','Report'],
      User.first.relationship_type_options
  end

  test '#delete! does what it needs to' do
    user = User.first
    assert_equal 'active', user.state
    assert user.surveys.open.any?
    assert user.surveys.for_self.open.any?
    user.delete!
    assert_equal 'deleted', user.state
    refute user.surveys.open.any?
    refute user.survey_plans.active.any?
  end

  test 'cannot create self-survey for inactive users' do
    user = User.first
    user.self_surveys.destroy_all
    user.survey_plans.for_self.update_all(next_due: Time.now)
    assert user.self_surveys_due?, "Self survey should be due"
    user.create_self_surveys
    assert user.self_surveys.any?, "Should be a self-survey"
    user.self_surveys.destroy_all
    user.survey_plans.for_self.update_all(next_due: Time.now)
    user.delete!
    refute user.self_surveys_due?
    assert_raises(RuntimeError) { user.create_self_surveys }
    refute user.self_surveys.any?
  end
end
