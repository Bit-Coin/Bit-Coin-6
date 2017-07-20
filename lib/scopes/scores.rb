# mixes into User
module Scopes::Scores

  def scores(options={})
    options[:characteristic] ||= Characteristic.ripple_effect_score.name
    options[:scope] ||= 'personal'
    case options[:scope]
    when 'personal'
      scoped = personal_scores
    when 'team'
      scoped = team.scores
    when 'cohort'
      scoped = Score.for_cohort(company: company, cohort: cohort)
    when 'company'
      scoped = company.scores_for_company
    else
      raise 'Undefined scope in Scopes::Scores'
    end

    if options[:characteristic] == 'all'
      # NOOP
    elsif options[:characteristic] == 'res_components' # everything except RES
      scoped = scoped.for_res_components
    else
      scoped = scoped.for_characteristic(options[:characteristic])
    end
    scoped.order(published_at: :desc)
  end
end