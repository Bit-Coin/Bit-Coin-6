class Api::V1::InvitationsController < Api::V1::BaseController
  respond_to :json

  # POST /api/v1/invitations
  def create
    # TODO fix me! Craziness.  If an ID is passed, use it.  Otherwise, try to find the 
    # user by email.  If one is found, make sure it's in the same company.
    # If not, explain it to the receiver.  If it is in the same company,
    # go ahead and use it.  If nothing is found, create an unregistered_giver.
    giver = params[:giver_id].present? ? User.find(params[:giver_id]) \
               : User.find_by_email(params[:email].downcase)
    if current_user.feedback_type.include?('giver')
      render json: 'You are not athorized for this action'
    elsif giver && giver == current_user
      # nope!
      render json: 'You cannot invite yourself.', status: 500 and return

    elsif giver && giver.unsubscribed?
      render json: "#{giver.email} has asked not to participate.", status: 500 and return

    elsif giver && giver.bouncing?
      render json: "Messages to #{giver.email} are bouncing.  Please delete and enter a new email address.",
        status: 500 and return

    elsif giver && giver.unresponsive?
      render json: "#{giver.email} has not responded to other invitations, so may not be seeing messages or is not participating.",
        status: 500 and return

    elsif giver && current_user.survey_plans.active.pluck(:giver_id).include?(giver.id)
      # can't invite someone twice
      render json: "#{giver.email} is already in your Ripplecrew.", status: 500 and return

    elsif giver && giver.company == current_user.company
      # great!

    elsif giver
      # explain that we can't do this yet
      render json: 'That address is registered with another company.', status: 500 and return

    else
      # giver is nil.  Survey_plan#build_from_params will create one
    end

    # Now we can create the plan
    sp = current_user.survey_plans.build_from_params(
      receiver: current_user,
      giver: giver, 
      email: params[:email]
    )
    if sp.save
      sp.create_next_survey
      sp.notify!
      render json: {
        active_plans: current_user.survey_plans.active.count,
        plan_id: sp.id
      }, status: :ok
    else
      render status: 500
    end
  end

  # DELETE /api/v1/invitations/:id
  def destroy
    sp = current_user.survey_plans.find(params[:id])
    if sp.delete! # soft delete
      render json: current_user.survey_plans, status: :ok
    else
      render json: '', status: 500
    end
  end

  # GET /api/v1/invitations/:id/resend
  def resend
    sp = current_user.survey_plans.find(params[:id])
    if sp.resend!
      flash[:notice] = "Invitation has been resent to #{sp.giver.email}."
      render plain: '', status: :ok
    else
      render json: "There was an error resending the invitation.", status: 500
    end
  end
end
