class Admin::ResponseSetsController < AdminController
  respond_to :html
  before_action :get_response_set, only: [:edit, :update, :destroy]
  before_action :catch_cancel, only: [:create, :update]

  def index
    @response_sets = ResponseSet.all
  end

  def new
    @rs = ResponseSet.new
  end

  def edit; end

  def create
    @rs = ResponseSet.create(strong_params)
    if @rs.persisted?
      flash[:notice] = 'Created'
      redirect_to admin_response_sets_path
    else
      flash[:error] = 'Error'
      render :edit
    end
  end

  def update
    if @rs.update_attributes(strong_params)
      flash[:notice] = 'Updated'
      redirect_to admin_response_sets_path
    else
      flash[:error] = 'Error'
      render :edit
    end
  end

  def destroy
    if @rs.questions.any?
      flash[:error] = "This response set has associated questions. Delete those first."
    else
      @rs.destroy
      flash[:notice] = "Deleted"
    end
    redirect_to admin_response_sets_path
  end

  private

  def get_response_set
    @rs = ResponseSet.find(params[:id])
  end

  def strong_params
    sp = params.require(:response_set).permit(:description, :values)
    sp[:values] = eval(sp[:values]) # cast string to hash for hstore data type
    sp
  end

  def catch_cancel
    if params[:commit] == 'Cancel'
      flash[:notice] = 'Operation canceled'
      redirect_to admin_response_sets_path and return
    end
  end
end
