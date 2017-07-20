class Admin::QuestionsController < AdminController
  respond_to :html
  before_action :get_question, only: [:edit, :update, :destroy]

  def index
    @questions = Question.includes(:response_set, :characteristic).order(:characteristic_id).all
  end

  def new
    @question = Question.new({
      parent_characteristic_id: params[:cm].to_i,
      other_phrased: "\#{receiver.first_name} "
    })
  end

  def create
    @question = Question.create(strong_params)
    if @question.id
      flash[:notice] = 'Created'
      redirect_to edit_admin_characteristic_path(@question.parent_characteristic)
    else
      flash[:error] = "Could not create question"
      respond_with @question
    end
  end

  def edit; end

  def update
    if @question.update_attributes(strong_params)
      flash[:notice] = 'Updated'
      redirect_to edit_admin_characteristic_path(@question.parent_characteristic)
    else
      respond_with @question
    end
  end

  def destroy
    if @question.responses.any?
      flash[:error] = 'Cannot delete questions with responses.  Contact dev.'
    else
      @question.destroy
      flash[:notice] = 'Deleted'
    end
    redirect_to edit_admin_characteristic_path(@question.parent_characteristic)
  end

  def check_responses
    @question = Question.find(params[:id])
    @responses = @question.responses.where("score is not NULL")
  end

  private

  def get_question
    @question = Question.find(params[:id])
  end

  def strong_params
    params.require(:question).permit(:characteristic_id, :other_phrased,
      :self_phrased, :response_set_id)
  end
end
