class Fixtures::Scores

  def self.duplicate(options={})
    options[:trend] ||= 'negative'
    options[:characteristic] ||= 'all'

    source_receiver = User.find(options[:source_receiver_id])
    target_receiver = User.find(options[:target_receiver_id])
    print "Duplicating scores for #{target_receiver.email}"
    
    source_receiver.scores(characteristic: options[:characteristic]).each do |score|
      duplicate = score.dup
      duplicate.receiver = target_receiver
      duplicate.score = derived_score(score.score, options[:trend], 50.0)
      duplicate.save
      print '.'
    end
    print "done.\n"
  end

  def self.derived_score(score, trend='neutral', range=20.0, min=0, max=5) # default +/- 20% of original
    case trend
    when 'negative'
      offset = range * 2
    when 'positive'
      offset = range / 2
    else
      offset = range # even chance of over or under 
    end
    factor = 1.0 + (rand(2 * range.to_f) - offset) / 100.0
    adjusted_score = score * factor
    adjusted_score < min ? min : adjusted_score
    adjusted_score > max ? max : adjusted_score
    adjusted_score
  end

end
