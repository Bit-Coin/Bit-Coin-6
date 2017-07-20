class Admin::InvitationsController < AdminController
  def index
    @headline = 'SurveyPlans Due'
    @survey_plans = SurveyPlan.due.order(:giver_id)
  end

  # GET /admin/invitations/status
  def status
    raise 'fix me'
    sql =<<-SQL
      select
        invitations.hold_until as hold_until_utc,
        teams.name as company,
        invitations.state,
        count(*)
      from invitations
      join users on invitations.giver_id = users.id
      join teams on users.company_id = teams.id
      where invitations.state in ('notified', 'active')
        and teams.type in ('client', 'pilot')
      group by hold_until_utc, invitations.state, company
      order by hold_until_utc desc
    SQL
    @table = ActiveRecord::Base.connection.exec_query sql
  end

  def stale
    raise 'fix me'
    @headline = 'Stale Invitations (unanswered after 3 days)'
    @invitations = Invitation.stale.order(:giver_id)
    render template: 'admin/invitations/index'
  end

  def destroy
    sp = SurveyPlan.find(params[:id])
    sp.destroy
    flash[:notice] = "SurveyPlan #{inv.id} deleted."
    redirect_to stale_admin_invitations_path
  end

  def resend
    sp = SurveyPlan.find(params[:id])
    if sp.resend!
      flash[:notice] = "SurveyPlan #{sp.id} has been resent."
    else
      flash[:error] = "SurveyPlan has no open survey."
    end
    redirect_to stale_admin_invitations_path
  end
end
