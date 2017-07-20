class Admin::SurveySetQuestionsController < AdminController
  respond_to :html
  before_action :get_survey_set_question, only: [:destroy]

  def new
    sset = SurveySet.find(params[:sset])
    @ssq = sset.survey_set_questions.build
    @question = Question.new(parent_characteristic_id: sset.survey_series.parent_characteristic_id)
  end

  def create
    ssq = SurveySetQuestion.create(strong_params)
    flash[:notice] = 'Question added to survey set'
    redirect_to edit_admin_survey_set_path(ssq.survey_set)
  end

  def destroy
    unless @ssq.question.responses.any?
      @ssq.destroy
      flash[:notice] = 'Question removed from survey set'
    else
      flash[:error] = 'Cannot remove question because surveys exist'
    end
    redirect_to edit_admin_survey_set_path(@ssq.survey_set)
  end

  private

  def get_survey_set_question
    @ssq = SurveySetQuestion.find(params[:id])
  end

  def strong_params
    params.require(:survey_set_question).permit(:question_id, :survey_set_id)
  end
end
