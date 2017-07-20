class Admin::DashboardsController < AdminController
  def show
    @companies = Company.all
  end
end
