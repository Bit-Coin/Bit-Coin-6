module ResqueWeb
  class OverviewController < ::AdminController
    def show
      render :layout => !request.xhr?, :locals => { :polling => request.xhr? }
    end
  end
end
