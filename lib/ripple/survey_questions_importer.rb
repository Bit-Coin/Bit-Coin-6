module Ripple
  
  class SurveyQuestionsImporter

    # USED IN TEST SEEDS
     
    # Provide a path to a suitable CSV file
    # Source sheets suitable for exporting can be found at
    # https://drive.google.com/open?id=1tnUJ589n1Dciog66LODhw0CJNvKtlhfqCl8w0H69S6o&authuser=0

    # See db/seeds/ripple50.csv for example
     
    # Import both self-and other-phrased
    # (Really only works for Ripple50)
    def self.import!(path, options={})
      ActiveRecord::Base.transaction do
        data = File.read(File.join(Rails.root, path))
        CSV.parse(data, :headers => true) do |row|
          import_row(row.to_h)
        end
      end
      puts "Imported questions from #{path}"
      true
    end

    # GIANT HACK
    def self.import_fannie_mae!(path, ssid)
      ActiveRecord::Base.transaction do
        data = File.read(File.join(Rails.root, path))
        CSV.parse(data, :headers => true) do |row|
          hashrow = row.to_h
          hashrow['survey_series_id'] = ssid
          hashrow['self_survey_series_id'] = ssid
          import_row(hashrow)
        end
      end
      puts "Imported questions from #{path}"
      true
    end

    private
    
    def self.import_row(row)
      others_survey_set = SurveySet.find_or_create_by({
        :name => row['survey_set_name'],
        :survey_series_id => row['survey_series_id']
      })
      if row['self_survey_set_name'] && row['self_survey_set_name'] != row['survey_set_name']
        self_survey_set = SurveySet.find_or_create_by({
          :name => row['self_survey_set_name'],
          :survey_series_id => row['self_survey_series_id']
        })
      end
      characteristic = Characteristic.where(:name => row['characteristic_name']).first
      raise "Cannot find charasteristic: #{row['characteristic_name']}" unless characteristic
      question = Question.create!({
        :characteristic => characteristic,
        :other_phrased => row['other_phrased'],
        :self_phrased => row['self_phrased'],
        :state => 'active'
      })
      others_survey_set.survey_set_questions.create!({
        :question => question
      })
      if self_survey_set
        self_survey_set.survey_set_questions.create!({
          :question => question
        })
      end
      true
    end
  end
end
