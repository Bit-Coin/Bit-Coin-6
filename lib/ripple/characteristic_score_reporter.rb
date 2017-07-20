module Ripple

  # This class efficiently marshals out score records
  # into a format that is easily digestible by views

  class CharacteristicScoreReporter

    attr_reader :user, :personal_scores, :company_scores, :self_scores, :competency_model,
                :published_at, :total_responses

    def initialize(user, competency_model=nil)
      @user = user
      @competency_model = competency_model || Characteristic.ripple_effect_score
      @personal_scores = []
      @company_scores = []
      @self_scores = []
      @published_at = ::Time.now
      @total_responses = 0
    end

    def fetch_all_scores
      @competency_model.self_with_components.each_with_index do |characteristic, i|
        # score = raw_personal_scores.find {|s| s && s.characteristic_id === characteristic.id}
        score = raw_personal_scores.where(:characteristic_id => characteristic.id).order("published_at DESC").first
        @personal_scores[i] = unpack_score_record(score || blank_score(characteristic))

        # score = raw_company_scores.find {|s| s && s.characteristic_id === characteristic.id}
        score = raw_company_scores.where(:characteristic_id => characteristic.id).order("published_at DESC").first
        @company_scores[i] = unpack_score_record(score || blank_score(characteristic))

        # score = raw_self_scores.find {|s| s && s.characteristic_id === characteristic.id}
        score = raw_self_scores.where(:characteristic_id => characteristic.id).order("published_at DESC").first
        @self_scores[i] = unpack_score_record(score || blank_score(characteristic))
      end
      if has_scores?
        set_published_at
        set_total_responses
        true
      else
        false
      end
    end

    def unpack_score_record(score)
      {
        :characteristic => {
          :id => score.characteristic.id,
          :name => score.characteristic.name,
          :score_name => score.characteristic.score_name,
          :description => score.characteristic.description
        },
        :scores => {
          :overall => score.mean.to_f.round(1),
          :profit => profit(score),
          :number => score.number.to_i,
          :created_at => score.created_at,
          :hist => [
            [1, score.hist1.to_f.round(2)],
            [2, score.hist2.to_f.round(2)],
            [3, score.hist3.to_f.round(2)],
            [4, score.hist4.to_f.round(2)],
            [5, score.hist5.to_f.round(2)]
          ]
        }
      }
    end

    def profit(score)
      scores = @user.personal_scores.characteristic_scores.where(characteristic_id: score.characteristic_id).order("published_at").last(2)
      latest_score = scores.last
      past_score = scores.first
      if past_score.nil?
        incdec = "0%"
      else
        incdec = sprintf("%+.2f%", (latest_score.mean.to_f.round(2) - past_score.mean.to_f.round(2))*100.0/past_score.mean.to_f.round(2))
      end
      incdec.include?("+0.00%") ? "0%" : incdec
    end

    # Active Record Quarantine Zone

    # Only render the dashboard if the receiver has personal scores,
    # i.e. scored feedback from others
    def has_scores?
      @user.personal_scores.published.any?
    end

    def blank_scores
      all_characteristics.map do |c|
        blank_score(c)
      end
    end

    def blank_score(characteristic)
      Score.new({
        :characteristic => characteristic,
        :receiver => @user,
        :company => @user.company,
        :created_at => nil,
        :number => 0,
        :mean => 0,
        :hist1 => 0.0,
        :hist2 => 0.0,
        :hist3 => 0.0,
        :hist4 => 0.0,
        :hist5 => 0.0
      })
    end

    def raw_personal_scores
      @rps ||= @user.personal_scores.published.characteristic_scores
    end

    def raw_company_scores
      @rcs ||= @user.company.scores_for_company.published.characteristic_scores
    end

    def raw_self_scores
      @rss ||= @user.self_scores.published.characteristic_scores
    end

    private

    def set_published_at
      return nil unless @rps && @rcs && @rss
      @published_at = (@rps.pluck(:published_at) + @rcs.pluck(:published_at) + @rss.pluck(:published_at)).last
    end

    def set_total_responses
      @total_responses = @personal_scores[0][:scores][:number]
    end
  end
end

# HELPFUL FOR TROUBLESHOOTING
# #fetch_all_scores =>
# {:personal=>
#   [{:characteristic=>{:id=>1, :name=>"ripple_effect_score", :description=>nil},
#     :scores=>
#      {:overall=>3.5,
#       :number=>260,
#       :created_at=>Fri, 22 May 2015 21:50:07 EDT -04:00,
#       :hist=>[[1, 0.02], [2, 0.09], [3, 0.38], [4, 0.41], [5, 0.1]]}},
#    {:characteristic=>
#      {:id=>2,
#       :name=>"curious",
#       :description=>"Inquisitive, Open Minded, Imaginative, Creative"},
#     :scores=>
#      {:overall=>3.9,
#       :number=>52,
#       :created_at=>Fri, 22 May 2015 21:50:07 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.0], [3, 0.27], [4, 0.6], [5, 0.13]]}},
#    {:characteristic=>
#      {:id=>3,
#       :name=>"conscientious",
#       :description=>"Hard Working, Persevering, Organized, Responsible"},
#     :scores=>
#      {:overall=>3.3,
#       :number=>52,
#       :created_at=>Fri, 22 May 2015 21:50:07 EDT -04:00,
#       :hist=>[[1, 0.06], [2, 0.12], [3, 0.44], [4, 0.29], [5, 0.1]]}},
#    {:characteristic=>
#      {:id=>4,
#       :name=>"committed",
#       :description=>"Engaged, Sociable, Colloquial, Assertive"},
#     :scores=>
#      {:overall=>3.1,
#       :number=>52,
#       :created_at=>Fri, 22 May 2015 21:50:07 EDT -04:00,
#       :hist=>[[1, 0.04], [2, 0.13], [3, 0.48], [4, 0.35], [5, 0.0]]}},
#    {:characteristic=>
#      {:id=>5,
#       :name=>"cooperative",
#       :description=>"Amiable, Sympathetic, Empathetic, Personable"},
#     :scores=>
#      {:overall=>3.7,
#       :number=>52,
#       :created_at=>Fri, 22 May 2015 21:50:07 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.04], [3, 0.4], [4, 0.42], [5, 0.13]]}},
#    {:characteristic=>
#      {:id=>6,
#       :name=>"consistent",
#       :description=>"Poised, Self-Confident, Steady, Calm Cool and Collected"},
#     :scores=>
#      {:overall=>3.5,
#       :number=>52,
#       :created_at=>Fri, 22 May 2015 21:50:07 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.15], [3, 0.33], [4, 0.4], [5, 0.12]]}}],
#  :company=>
#   [{:characteristic=>{:id=>1, :name=>"ripple_effect_score", :description=>nil},
#     :scores=>
#      {:overall=>3.5,
#       :number=>1865,
#       :created_at=>Fri, 22 May 2015 21:50:08 EDT -04:00,
#       :hist=>[[1, 0.04], [2, 0.09], [3, 0.35], [4, 0.39], [5, 0.13]]}},
#    {:characteristic=>
#      {:id=>2,
#       :name=>"curious",
#       :description=>"Inquisitive, Open Minded, Imaginative, Creative"},
#     :scores=>
#      {:overall=>3.6,
#       :number=>373,
#       :created_at=>Fri, 22 May 2015 21:50:08 EDT -04:00,
#       :hist=>[[1, 0.05], [2, 0.05], [3, 0.33], [4, 0.42], [5, 0.15]]}},
#    {:characteristic=>
#      {:id=>3,
#       :name=>"conscientious",
#       :description=>"Hard Working, Persevering, Organized, Responsible"},
#     :scores=>
#      {:overall=>3.5,
#       :number=>373,
#       :created_at=>Fri, 22 May 2015 21:50:08 EDT -04:00,
#       :hist=>[[1, 0.04], [2, 0.08], [3, 0.32], [4, 0.41], [5, 0.14]]}},
#    {:characteristic=>
#      {:id=>4,
#       :name=>"committed",
#       :description=>"Engaged, Sociable, Colloquial, Assertive"},
#     :scores=>
#      {:overall=>3.3,
#       :number=>373,
#       :created_at=>Fri, 22 May 2015 21:50:08 EDT -04:00,
#       :hist=>[[1, 0.04], [2, 0.12], [3, 0.4], [4, 0.36], [5, 0.08]]}},
#    {:characteristic=>
#      {:id=>5,
#       :name=>"cooperative",
#       :description=>"Amiable, Sympathetic, Empathetic, Personable"},
#     :scores=>
#      {:overall=>3.6,
#       :number=>373,
#       :created_at=>Fri, 22 May 2015 21:50:08 EDT -04:00,
#       :hist=>[[1, 0.04], [2, 0.08], [3, 0.32], [4, 0.42], [5, 0.14]]}},
#    {:characteristic=>
#      {:id=>6,
#       :name=>"consistent",
#       :description=>"Poised, Self-Confident, Steady, Calm Cool and Collected"},
#     :scores=>
#      {:overall=>3.4,
#       :number=>373,
#       :created_at=>Fri, 22 May 2015 21:50:08 EDT -04:00,
#       :hist=>[[1, 0.04], [2, 0.12], [3, 0.36], [4, 0.36], [5, 0.13]]}}],
#  :self=>
#   [{:characteristic=>{:id=>1, :name=>"ripple_effect_score", :description=>nil},
#     :scores=>
#      {:overall=>3.8,
#       :number=>50,
#       :created_at=>Mon, 11 May 2015 16:00:05 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.0], [3, 0.32], [4, 0.52], [5, 0.16]]}},
#    {:characteristic=>
#      {:id=>2,
#       :name=>"curious",
#       :description=>"Inquisitive, Open Minded, Imaginative, Creative"},
#     :scores=>
#      {:overall=>4.3,
#       :number=>10,
#       :created_at=>Mon, 11 May 2015 16:00:05 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.0], [3, 0.0], [4, 0.7], [5, 0.3]]}},
#    {:characteristic=>
#      {:id=>3,
#       :name=>"conscientious",
#       :description=>"Hard Working, Persevering, Organized, Responsible"},
#     :scores=>
#      {:overall=>3.4,
#       :number=>10,
#       :created_at=>Mon, 11 May 2015 16:00:05 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.0], [3, 0.6], [4, 0.4], [5, 0.0]]}},
#    {:characteristic=>
#      {:id=>4,
#       :name=>"committed",
#       :description=>"Engaged, Sociable, Colloquial, Assertive"},
#     :scores=>
#      {:overall=>3.4,
#       :number=>10,
#       :created_at=>Mon, 11 May 2015 16:00:05 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.0], [3, 0.6], [4, 0.4], [5, 0.0]]}},
#    {:characteristic=>
#      {:id=>5,
#       :name=>"cooperative",
#       :description=>"Amiable, Sympathetic, Empathetic, Personable"},
#     :scores=>
#      {:overall=>4.3,
#       :number=>10,
#       :created_at=>Mon, 11 May 2015 16:00:05 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.0], [3, 0.1], [4, 0.5], [5, 0.4]]}},
#    {:characteristic=>
#      {:id=>6,
#       :name=>"consistent",
#       :description=>"Poised, Self-Confident, Steady, Calm Cool and Collected"},
#     :scores=>
#      {:overall=>3.8,
#       :number=>10,
#       :created_at=>Mon, 11 May 2015 16:00:05 EDT -04:00,
#       :hist=>[[1, 0.0], [2, 0.0], [3, 0.3], [4, 0.6], [5, 0.1]]}}]}
