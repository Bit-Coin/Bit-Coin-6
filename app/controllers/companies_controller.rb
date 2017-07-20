class CompaniesController < ApplicationController

  before_action :set_company

  def update
    if params[:commit] == 'Yes'
      domain = params[:company][:domain]
    else
      domain = nil
    end
    @company.update_attributes(domain: domain)
    redirect_to '/invitations/manage', notice: "#{@company.name} associated with #{@company.domain} domain"
  end

  protected

  def set_company
    raise 'Company mismatch' unless current_user.company.id == params[:id].to_i
    @company = current_user.company
  end

  def strong_params
    params.require(:company).permit(:domain)
  end
end
