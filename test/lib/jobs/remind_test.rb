require 'test_helper'

class Job::RemindTest < ActiveSupport::TestCase

  describe Job::Remind do

    before do
      AcmeHelper.generate_acme_company_data(2)
      AcmeHelper.generate_acme_unregistered_givers(1)
    end

    # These don't belong here.
    # These should be unit tests on User#need_reminding
    
    it 'does not remind at the wrong time' do
      # by default, no User has this :reminder_hour set
      Timecop.freeze Time.new(2015, 03, 11, 10, 59, 00)
      assert_equal "No one to remind right now", Job::Remind.perform
    end

    it 'does remind at the right time' do
      # 8 is the default :reminder_hour
      
      Timecop.freeze Time.new(2015, 03, 10, 8, 34, 00)
      c = User.need_reminding.count
      assert_equal "#{c} Users were reminded and 0 marked unresponsive",
        Job::Remind.perform
    end

    it 'respects the company :reminder_hour' do
      Company.first.set_config(:reminder_hour, 17)
      Timecop.freeze Time.new(2015, 03, 10, 17, 34, 00)
      c = User.need_reminding.count
      assert_equal "#{c} Users were reminded and 0 marked unresponsive",
        Job::Remind.perform
    end

    it 'respects user :reminder_hour' do
      User.first.set_config(:reminder_hour, 21)
      Timecop.freeze Time.new(2015, 03, 10, 21, 34, 00)
      User.first.surveys.update_all(state: 'open')
      c = User.need_reminding.count
      assert_equal "#{c} Users were reminded and 0 marked unresponsive",
        Job::Remind.perform
    end

    it 'marks unresponsive' do
      bad_doobie = User.unregistered_givers.invited.first
      assert bad_doobie, 'No bad doobie?!'
      Timecop.freeze(Date.parse("Tuesday") + 7.days + 8.hours +
        bad_doobie.company.settings[:weeks_until_invitations_expire].weeks +
        1.second) # make sure we're far enough in the future
      bad_doobie.set_config(:reminder_hour, Time.now.hour)
      Job::Remind.perform
      assert_equal 'unresponsive', bad_doobie.reload.state
      assert_equal 'unregistered_giver', bad_doobie.type
    end

  end
end
