class CompaniesMailerPreview < ActionMailer::Preview
  def welcome_to_beta
    CompaniesMailer.welcome_to_beta(User.first.id)
  end
end
