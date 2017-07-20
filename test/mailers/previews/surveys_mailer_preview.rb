class SurveysMailerPreview < ActionMailer::Preview
  def new_invitation_spoofed
    survey = Survey.open.first
    survey.invitation.update_attributes(state: 'pending')
    survey.receiver.company.set_config(:spoof_receiver_email, true)
    SurveysMailer.new_invitation(survey.id)
  end

  def new_invitation_not_spoofed
    survey = Survey.open.first
    survey.invitation.update_attributes(state: 'pending')
    survey.receiver.company.set_config(:spoof_receiver_email, false)
    SurveysMailer.new_invitation(survey.id)
  end
end
