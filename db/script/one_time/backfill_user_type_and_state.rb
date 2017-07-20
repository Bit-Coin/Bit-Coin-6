class User
  def infer_type
    if Invitation.where('receiver_id = ?', id).any?
      'rippler'
    elsif company.present?
      'unregistered_giver'
    else
      'prospect'
    end
  end
end

# backfill users.type & state
# log to file in dev, but STDOUT on Heroku
logfile = File.open('log/backfill.log', File::WRONLY | File::CREAT)
logger = Rails.env.development? ? Logger.new(logfile) : Logger.new(STDOUT)
logger.info "Processing #{User.count} users"
User.all.each do |u|

  case u.state
  when 'active'
    u.type = u.infer_type

  when 'unresponsive'
    u.type = u.infer_type

  when 'unsubscribed'
    u.type = u.infer_type

  when 'deleted'
    u.type = u.infer_type

  when 'bouncing'
    u.type = u.infer_type

  when 'pending' # change to 'prospect'
    u.type = 'prospect'
    u.state = 'active'
    u.pending_company_name = 'Unknown' unless u.pending_company_name.present?

  when 'rippler'
    u.type = 'rippler'
    u.state = 'active'

  when 'unregistered_giver'
    u.type = u.infer_type # clean up mistaken ugs
    if u.type == 'unregistered_giver' && u.surveys.for_self.any?
      u.surveys.for_self.destroy_all
      logger.info "#{u.id} #{u.email} self-survey deleted"
    elsif u.type == 'rippler'
      logger.info "#{u.id} #{u.email} changed from unregistered_giver to rippler"
    end
    u.state = 'active'

  else
    logger.error "#{u.id} #{u.email} unknown state: '#{u.state}'"
  end

  if u.save
    logger.info "#{u.id} #{u.email} saved type/state: #{u.type}/#{u.state}"
  else
    logger.error "#{u.id} #{u.email} could not save: #{u.errors.full_messages}"
  end

end
logger.info "Done"
logger.close if Rails.env.development?
