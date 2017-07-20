class SurveysMailer < BaseMailer
  layout 'email'

  def new_invitation(survey_id)
    @survey = Survey.find(survey_id)
    unless @survey.survey_plan.active? # allow skipping in seeds

      mail_hash = {to: @survey.giver.email}
      if @survey.receiver.company.settings[:spoof_receiver_email]
        mail_hash.merge!({
          subject: "Looking for feedback",
          from: "#{@survey.receiver.full_name} <#{@survey.receiver.email}>",
          template_name: 'new_invitation_spoofed'
        })
      else
        mail_hash.merge!({
          subject: "#{@survey.receiver.full_name} wants your feedback",
          # from:  use default
          template_name: 'new_invitation_not_spoofed'
        })
      end
      message = mail(mail_hash)
    end
    message
  end

  # TODO new_invitation_sms
end
