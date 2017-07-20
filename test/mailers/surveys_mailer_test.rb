require 'test_helper'

class SurveysMailerTest < ActiveSupport::TestCase
  
  before do
    AcmeHelper.generate_acme_company
    AcmeHelper.generate_acme_users(2)
    AcmeHelper.generate_acme_plans_and_surveys
  end

  test 'new invitation with spoofed receiver address' do
    survey = Survey.open.for_others.first
    survey.survey_plan.update_attributes(state: 'created')
    SurveysMailer.new_invitation(survey.id).deliver
    assert_equal [survey.giver.email], ActionMailer::Base.deliveries.last.to
    assert_equal [survey.receiver.email], ActionMailer::Base.deliveries.last.from
    assert_match /@ripplecrew.com$/, ActionMailer::Base.deliveries.last.message_id
    assert_equal Message.last.uuid, ActionMailer::Base.deliveries.last.message_id
    assert_equal 'SurveysMailer#new_invitation', Message.last.sender
    assert_equal survey, Message.last.messageable
  end

  test 'new invitation with ripple reply-to address' do
    survey = Survey.open.for_others.first
    survey.survey_plan.update_attributes(state: 'created')
    survey.receiver.company.set_config(:spoof_receiver_email, false)
    SurveysMailer.new_invitation(survey.id).deliver
    assert_equal [survey.giver.email], ActionMailer::Base.deliveries.last.to
    assert_equal ['no-reply@ripplecrew.com'], ActionMailer::Base.deliveries.last.from
    assert_match /@ripplecrew.com$/, ActionMailer::Base.deliveries.last.message_id
    assert_equal Message.last.uuid, ActionMailer::Base.deliveries.last.message_id
    assert_equal 'SurveysMailer#new_invitation', Message.last.sender
    assert_equal survey, Message.last.messageable
  end
end
