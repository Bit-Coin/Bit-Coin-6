class Admin::CharacteristicsController < AdminController
  respond_to :html
  before_action :get_competency_model, only: [:edit, :update, 
      :edit_components, :edit_questions, :update_components, :destroy]
  before_action :catch_cancel, only: [:update, :create]

  def index
    @competencies = Characteristic.where('parent_characteristic_id is null')
  end

  def new
    @cm = Characteristic.new
  end

  def edit; end

  def update
    if @cm.update_attributes(strong_params)
      flash[:notice] = "Updated"
      @cm = @cm.parent_characteristic if @cm.parent_characteristic.present?
      redirect_to edit_admin_characteristic_path(@cm)
    else
      flash[:error] = 'Error'
      respond_with @cm
    end
  end

  def create
    @cm = Characteristic.create(strong_params)
    if @cm.persisted? && @cm.parent_characteristic.present?
      @cm = @cm.parent_characteristic # return to the parent
      redirect_to component_admin_characteristic_path(@cm) and return
    elsif @cm.persisted?
      flash[:notice] = "Created"
      redirect_to admin_characteristics_path
    else
      flash[:error] = "Error"
      respond_with @cm
    end

  end

  def destroy
    if @cm.parent_characteristic_id.blank?
      flash[:error] = 'Not yet implemented.  Contact dev.'
      redirect_to :back and return
    end

    if @cm.questions.any?
      flash[:error] = 'Cannot delete characteristic with questions'
      render :edit_components and return
    end

    parent = @cm.parent_characteristic
    @cm.destroy
    @cm = parent
    flash[:notice] = 'Component was deleted'
    render :edit_components
  end

  # GET admin/characteristics/:id/components
  # component_admin_characteristic_path(@cm)
  def edit_components; end

  # GET admin/characteristics/:id/questions
  # questions_admin_characteristic_path(@cm)
  def edit_questions; end

  def edit_component
    @characteristic = Characteristic.find(params[:id])
  end

  private

  def get_competency_model
    @cm = Characteristic.find(params[:id])
  end

  def strong_params
    params.require(:characteristic).permit(:name, :score_name, :survey_name, :icon, :parent_characteristic_id,
        :description)
  end

  def catch_cancel
    if params[:commit] == "Cancel"
      flash[:notice] = 'Operation canceled'
      redirect_to admin_characteristics_path 
    end
  end
end
