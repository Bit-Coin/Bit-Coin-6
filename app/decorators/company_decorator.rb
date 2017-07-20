class CompanyDecorator < Draper::Decorator
  include ActionView::Helpers
  delegate_all

  def name_for_emails(options={})
    if options[:prepend_at] 
      string = " at #{object.name}"
    elsif (object.name != nil) && (object.name != "")
      string = " #{object.name}"
    else
      nil
    end

    if options[:strip_trailing_period] && string[-1, 1] == '.'
      string[0..-2]
    else
      string
    end
  end
end
