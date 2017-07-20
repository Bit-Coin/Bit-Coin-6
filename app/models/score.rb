class Score < ActiveRecord::Base
  belongs_to :company
  belongs_to :team
  belongs_to :characteristic
  belongs_to :question
  belongs_to :receiver, class_name: 'User'
  
  store_accessor :stats, :number, :sum, :variance, :standard_deviation, 
    :min, :max, :mean, :mode, :median, :range, :q1, :q2, :q3, 
    :hist1, :hist2, :hist3, :hist4, :hist5

  # TODO self.on_date

  STATES = %w( pending published past void )

  # TODO validate state

  # Scopes
  def self.for_teams(team_ids)
    raise 'team_ids are for different companies' \
      if Team.where('id in (?)', team_ids).unique_company_ids.size > 1
    where('team_id in (?)', team_ids)
  end

  def self.published
    where(:state => 'published')
  end

  def self.personal(user)
    user.scores
  end

  def self.for_users(user_ids)
    where('receiver_id in (?)', user_ids)
  end

  def self.for_cohort(options={})
    company = options[:company]
    cohort = options[:cohort]
    company.scores.where('cohort_name = ?', cohort)
  end
  
  def self.for_parent_characteristic(pc_id)
    ids = Characteristic.find(pc_id).all_questions.pluck(:id)
    where('question_id in (?)', ids)
  end

  def self.for_characteristic(name)
    joins(:characteristic).where('characteristics.name = ?', name)
  end

  def self.for_res_components
    joins(:characteristic).where('characteristics.id <> ?', Characteristic.ripple_effect_score.id)
  end

  def self.characteristic_scores
    where('scores.characteristic_id is not null').includes(:characteristic).order(:characteristic_id)
  end
  
  def self.question_scores
    where('scores.question_id is not null').includes(:question).order(:question_id)
  end

  # Instance methods

  def generation_name
    return receiver.full_name if receiver_id
    return team.name if team_id
    return cohort_name if cohort_name
    return company.name
  end
end

# format of stats hstore
 # => {"q1"=>"3.0", 
 #  "q2"=>"4.0", "q3"=>"4.0", "max"=>"5", 
 #  "min"=>"2", "sum"=>"1187.0", "mean"=>"3.596969696969697", 
 #  "mode"=>"4", "hist1"=>"0.0", "hist2"=>"0.10303030303030303", 
 #  "hist3"=>"0.3484848484848485", "hist4"=>"0.396969696969697", 
 #  "hist5"=>"0.15151515151515152", "range"=>"3.0", "median"=>"4.0", 
 #  "number"=>"330.0", "variance"=>"0.7496877869605131", 
 #  "standard_deviation"=>"0.8658451287386868"}
