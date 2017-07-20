class CustomDeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    user = User.first
    CustomDeviseMailer.confirmation_instructions(user, user.confirmation_token)
  end

  def reset_password_instructions
    user = User.first
    CustomDeviseMailer.reset_password_instructions(user, user.reset_password_token)
  end

  def maven_signed_you_up
    c = Company.find_by_stub('acme')
    c.update_attributes(manager_id: c.members.first.id)
    CustomDeviseMailer.maven_signed_you_up(c.members.ripplers.where('id != ?', c.manager_id).first.id)
  end

  def activate_carecloud_receiver
    # For CareCloud, the manager/maven is the receiver
    c = Company.find_by_stub('acme')
    c.update_attributes(manager_id: c.members.first.id)
    CustomDeviseMailer.activate_carecloud_receiver(c.members.ripplers.where('id = ?', c.manager_id).first)
  end

  def activate_carecloud_giver
    # For CareCloud, the givers are everybody except the manager/maven
    c = Company.find_by_stub('acme')
    c.update_attributes(manager_id: c.members.first.id)
    CustomDeviseMailer.activate_carecloud_giver(c.members.ripplers.where('id != ?', c.manager_id).first.id)
  end

  def activate_r50_giver
    c = Company.find_by_stub('acme')
    c.update_attributes(manager_id: c.members.first.id)
    CustomDeviseMailer.activate_r50_giver(c.members.ripplers.where('id != ?', c.manager_id).first.id)
  end

  def happy_new_year
    c = Company.find_by_stub('acme')
    c.update_attributes(manager_id: c.members.first.id)
    CustomDeviseMailer.happy_new_year(c.members.ripplers.where('id != ?', c.manager_id).first.id)
  end
end
