class Admin::RolesController < AdminController
  respond_to :html
  before_action :get_role, only: [:edit, :update, :destroy]
  before_action :catch_cancel

  def index
    @roles = Role.all
  end

  def new
    @role = Role.new
  end

  def edit; end

  def create
    @role = Role.create(strong_params)
    if @role.persisted?
      flash[:notice] = 'Created'
      redirect_to admin_roles_path
    else
      flash[:error] = 'Error'
      respond_with @role
    end
  end

  def update
    if @role.update_attributes(strong_params)
      flash[:notice] = 'Updated'
      redirect_to admin_roles_path
    else
      flash[:error] = 'Error'
      respond_with @role
    end
  end

  def destroy
    if @role.user_roles.any?
      flash[:error] = "This role is assigned to users.  Remove those first."
    else
      @role.destroy
      flash[:notice] = "Deleted"
    end
    redirect_to admin_roles_path
  end

  private

  def get_role
    @role = Role.find(params[:id])
  end

  def strong_params
    params.require(:role).permit(:name, :description)
  end

  def catch_cancel
    if params[:commit] == 'Cancel'
      flash[:notice] = 'Operation canceled'
      redirect_to admin_roles_path and return
    end
  end
end
