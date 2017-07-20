class InvitationsController < ApplicationController

  # Huge red herring!!!!  The Invitation model is deprecated in 
  # favor of SurveyPlan, but this controller is still named
  # InvitationsController and acts on SurveyPlan records.

  def manage
    # block in :consultant_mode
    unless current_user.company.settings[:consultant_mode]
      # TODO this is ugly and not good security practice
      @givers = current_user.not_yet_invited_company.map do |g|
        {value: g.email, giver_id: g.id}
      end.to_json.html_safe
    else
      redirect_to '/dashboard'
    end
  end

  def index
  end

  def view_message
    @invitation = current_user.invitations.build(giver: current_user)
    @survey = @invitation.surveys.build(giver: current_user, receiver: current_user)
    @sample = true # hack to trick the view
    render template: 'surveys_mailer/new_invitation', layout: 'application'
  end

  # POST handled in CompaniesController
  def confirm_domain
  end

  # Confusing:  why is this here and other actions are in the API controller?
  # PUT /invitations/:id
  def update
    @invitation = current_user.receiver_survey_plans.find(params[:id])
    @invitation.update_attributes(strong_params)
    redirect_to manage_invitations_path
  end

  protected

  def strong_params
    params.require(:survey_plan).permit(:relationship_type)
  end

end
