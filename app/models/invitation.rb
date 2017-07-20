class Invitation < ActiveRecord::Base
  
  # Can't just remove this.  Needed for migration script.
  
  include Eventable
  
  belongs_to :receiver, class_name: 'User'
  belongs_to :giver, class_name: 'User'
  
  # Invitation is deprecated in favor of SurveyPlan
  # make model read only until we remove it
  def readonly?
    true
  end

  validates_presence_of :giver, :receiver, :state, :reminded_at

  class << self
  end

  # TODO should be driven by company survey series
  def send_new_invitation_message
    raise 'kill me'
    ActiveRecord::Base.transaction do
      css = company.company_survey_series.ripple50_others
      survey = Ripple::SurveyAssigner.new(giver, receiver, css).create_next_survey
      # Surveys for 'active' invitations will not get sent, but survey will be opened
      # see SurveysMailer.new_invitation
      SurveysMailer.new_invitation(survey.id).deliver
      update_attributes(reminded_at: Time.now, hold_until: next_due)

      message = "#{self.receiver.email} sent an invitation to #{self.giver.email}"
      logger = Ripple::ActivityLogger.new(:text => message, :icon_emoji => ':mailbox:')
      logger.log!
    end
  end
end
