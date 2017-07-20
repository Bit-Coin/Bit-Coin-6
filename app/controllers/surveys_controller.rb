class SurveysController < ApplicationController
  require 'descriptive_statistics'

  skip_before_action :authenticate_user! # required for token auth
  skip_before_action :require_company_context
  acts_as_token_authentication_handler_for User,
      only: [:edit, :update, :done, :decline, :next_survey, :self_survey, :complete]
  before_action :authenticate_user!
  before_action :require_company_context

  def index
    if current_user.surveys.open.count == 1
      redirect_to edit_survey_path(current_user.surveys.open.first)
    elsif current_user.surveys.open.any?
      @surveys = current_user.surveys.open.order(created_at: :asc).decorate
    else
      render :done
    end
  end

  # Entry point for tokenized session
  def next_survey
    Ripple::CompanyContext.company = current_user.company
    current_user.well_look_whos_here!
    if current_user.feedback_type.nil? || current_user.feedback_type.include?('giver')
      if current_user.surveys.open.any?
        redirect_to edit_survey_path current_user.next_survey,
          user_email: params[:user_email],
          user_token: params[:user_token],
          host: params[:host]
      else
        render :done
      end
    else
      redirect_to dashboard_path, notice: 'Not authorized for the action'
    end
  end

  # GET '/surveys/self'
  def self_survey
    Ripple::CompanyContext.company = current_user.company
    if current_user.self_surveys.open.any?
      redirect_to edit_survey_path current_user.self_surveys.first,
        user_email: params[:user_email],
        user_token: params[:user_token],
        host: params[:host]
    else
      render :done
    end
  end

  def edit
    Ripple::CompanyContext.company = current_user.company
    current_survey = current_user.open_surveys
      .includes({responses: :question})
      .find(params[:id])
    other_open_surveys = current_user.open_surveys_excluding(current_survey)
      .includes({responses: :question})
    @survey = OpenStruct.new(
      parent_characteristic: current_survey.parent_characteristic,
      current_survey: current_survey.decorate,
      open_surveys_count: other_open_surveys.count,
      next_survey: other_open_surveys.decorate.first,
      percent_complete: Proc.new do
        starting_open = 5 # TODO hack.  Should stash the starting count in the session.
        still_open = current_user.surveys.open.count
        if still_open <= starting_open
          (((starting_open - still_open) / starting_open.to_f ) * 100).to_i
        else
          0
        end
      end.call
    )
    @select_options = [['General', 0]] # used for comments
  end

  # PUT /surveys/:id/complete
  def complete
    @survey = current_user.surveys.find(params[:id])
    Ripple::CompanyContext.company = current_user.company
    if persist_and_complete!
      next_survey
    else
      flash[:error] = "There was a problem saving your survey."
      redirect_to :back
    end
    @survey_responses = Survey.where("receiver_id = ?", @survey.receiver_id).scorable.collect(&:responses).flatten
    by_characteristic = {}
    by_question = {}
    current_user.company.company_survey_series.active.each do |css|
      pc = css.survey_series.parent_characteristic
      by_characteristic[pc.id] = Ripple::DescriptiveStatisticsArray.new
      pc.components.each do |cc|
        by_characteristic[cc.id] = Ripple::DescriptiveStatisticsArray.new
      end
    end
    @survey_responses.each do |r|
      if r.score
        # assign to characteristic
        if by_characteristic.keys.include?(r.characteristic_id)
          by_characteristic[r.characteristic_id] << r.score
        end

        # assign to parent_characteristic if necessary
        if r.characteristic.parent_characteristic_id && by_characteristic.keys.include?(r.characteristic.parent_characteristic_id)
          by_characteristic[r.characteristic.parent_characteristic_id] <<  r.score
        end

        # assign to question
        if by_question[r.question_id].nil?
          by_question[r.question_id] = Ripple::DescriptiveStatisticsArray.new
        end
        by_question[r.question_id] << r.score
      end
    end

    if @survey.receiver.eql?(current_user)
      @survey.receiver.self_scores.update_all(state: 'past') if @survey.receiver.self_scores.present?
    else
      @survey.receiver.personal_scores.update_all(state: 'past') if @survey.receiver.personal_scores.present?
    end
    cohort_name = current_user.eql?(@survey.receiver) ? 'self' : nil
    by_characteristic.each do |characteristic_id, score_array|
      next unless score_array.present?
      create_scores(nil, characteristic_id, cohort_name, score_array)
    end
    by_question.each do |question_id, score_array|
      next unless score_array.present?
      create_scores(question_id, nil, cohort_name, score_array)
    end
  end

  # GET /surveys/:id/done
  def done
    Ripple::CompanyContext.company = current_user.company
    current_survey = current_user.surveys.find(params[:id]).decorate
    current_survey.complete!
  end

  # PUT /surveys/:id/decline
  def decline
    Ripple::CompanyContext.company = current_user.company
    survey = current_user.surveys.find(params[:id])
    survey.decline!
    flash[:notice] = "You will no longer receive surveys for #{survey.receiver.full_name}."
    next_survey
  end

  protected

  def create_scores(que_id, char_id, cohort_name, score_array = [])
    if score_array.length === 0
      score_array << 0 # Your score will be 0, even less than 1; think on this
    end
    stats = score_array.descriptive_statistics
    stats = stats.merge(hist_five(stats[:number],score_array))
    @survey.receiver.scores.create!({
      :company_id => @survey.receiver.company_id,
      :characteristic_id => char_id,
      :question_id => que_id,
      :stats => stats,
      :cohort_name => cohort_name,
      :state => 'published',
      :published_at => DateTime.now
    })

    current_user.company.scores.create!({
        :company_id => @survey.receiver.company_id,
        :characteristic_id => char_id,
        :question_id => que_id,
        :stats => stats,
        :cohort_name => 'company',
        :state => 'published',
        :published_at => DateTime.now
      })

  end

  def persist_and_complete!
    # => {"utf8"=>"✓",
    #  "_method"=>"put",
    #  "authenticity_token"=>
    #   "/PTsm/k+7xMdesYffojSsTEzEYZfSBm9/T2972eS3+7IansML6GF9rENl4hg/22yPR7XJ870Hxlan1LlKQAjxg==",
    #  "hidden_comments_input"=>
    #   "[{\"response_id\":\"0\",\"comment_text\":\"angie\"}]",
    #  "commit"=>"<span class='badge'>2 more</span> Next >>",
    #  "controller"=>"surveys",
    #  "action"=>"complete",
    #  "id"=>"10528"}
    begin
      ActiveRecord::Base.transaction do
        if params[:hidden_comments_input].present?
          comments = JSON.parse(params[:hidden_comments_input])
          comments.each do |comment|
            receiver_id = @survey.receiver_id
            response_id = comment['response_id'] == '0' ? nil : comment['response_id'].to_i
            survey_id = @survey.id
            Comment.create!({
              receiver_id: receiver_id,
              response_id: response_id,
              survey_id: survey_id,
              text: comment['comment_text'],
              state: 'final'
            })
          end
        end
        @survey.complete!
      end
    rescue
      false
    else
      true
    end
  end

  protected
     def hist_five(total, score_array)
      {
        :hist1 => hist_n(1, total, score_array),
        :hist2 => hist_n(2, total, score_array),
        :hist3 => hist_n(3, total, score_array),
        :hist4 => hist_n(4, total, score_array),
        :hist5 => hist_n(5, total, score_array)
      }
    end

    # Faster than any block/iterator method

    def hist_n(n, total, score_array)
      i = score_array.length
      count = 0
      while i > 0
        i -= 1
        count += 1 if score_array[i] === n
      end
      count.to_f / total
    end

end
