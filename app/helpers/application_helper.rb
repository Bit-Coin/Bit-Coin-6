module ApplicationHelper
  def bootstrap_class_for flash_type
    { 'success' => "alert-success",
      'error' => "alert-danger",
      'alert' => "alert-warning",
      'notice' => "alert-info" }[flash_type] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
              concat content_tag(:button, 'x', class: "close", data: { dismiss: 'alert' })
              concat message
            end)
    end
    nil
  end

  def time_to_complete_surveys(user)
    min = user.surveys.open.count / 2
    min = min == 0 ? 1 : min
    if min == 1
      "one minute"
    else
      "#{min} minutes"
    end
  end

  def suggested_company_name(maven)
    # TODO If two people indicate they're from the same company...
    name = maven.pending_company_name
    name ||= "#{maven.first_name}'s Ripplecrew" if maven.first_name.present?
    name ||= "#{maven.email.split('@')[0].humanize}'s Ripplecrew"
    i = 1
    until Company.find_by_name(name).blank? # make sure we don't have a name collision
      i += 1
    end
    name += " (#{i})" if i > 1 # e.g. "Joe's Ripplecrew (4)"

    name
  end

  def suggested_company_stub(maven)
    if maven.pending_company_name
      maven.pending_company_name.split(' ').first.downcase.slice(0,12)
    else
      ''
    end
  end

  def list_parent_characteristics(company)
    company.parent_characteristics.pluck(:description).join(', ').html_safe
  end

  def survey_name(user=nil)
    user ||= current_user
    pcs = user.company.parent_characteristics
    if pcs.count > 1
      "survey"
    else
      pcs.first.survey_name
    end
  end

  def indefinite_article(noun)
    %w(a e i o u).include?(noun[0].downcase) ? "an #{noun}" : "a #{noun}"
  end

  def tokenized?
    session[:tokenized?]
  end

  def current_quarter_label
    "#{Date.today.year} Q#{((date.month - 1) / 3) + 1}"
  end

  # adds the right class to Survey edit buttons
  def response_button_class(response, value)
    response.score == value ? 'selected' : 'not-selected'
  end

  def ajax_spinner_class(response)
    response.score.blank? ? 'hidden' : 'hidden'
  end

  def big_survey_button_text
    if @survey.open_surveys_count > 0
      "<span class='badge'>#{@survey.open_surveys_count} more</span> Next >>"
    else
      "Finish"
    end
  end

  def done_surveys_url(giver)
    root_url(:host => Ripple::CompanyContext.company.host) + 'surveys/done?user_email=' +
      CGI.escape(giver.email) + '&user_token=' +
      CGI.escape(giver.authentication_token)
  end

  def navbar_surveys_button(count)
    "Give Feedback <span class='badge'>#{count}</span>".html_safe
  end

  def csv_sample(rows=3)
    csv = "\"first_name\",\"last_name\",\"email\"\n"
    rows.times do
      csv += "\"#{Faker::Name.first_name}\",\"#{Faker::Name.last_name}\",\"#{Faker::Internet.email}\"\n"
    end
    csv
  end

  def check_dashboard
    if current_user.company.settings[:show_dashboard] == "true"
      "on"
    else
      "off"
    end
  end

  def response_count(responses, score)
    responses.select {|r| r.score == score}.count
  end

  def collect_score(responses,score)
    responses.select {|r| r.score == score}.collect(&:score)
  end
end
