# NB This migration has several post-run scripts!
# If you want to see a picture of this:
#  https://docs.google.com/drawings/d/1FdjcKL8w6eF8WRBQMQcvuEXUWlS9lCSfk5hEg9hHE10/edit

class ProjectsEtc < ActiveRecord::Migration
  def change

    create_table :survey_plans do |t|
      t.timestamps
      t.integer :user_role_id, null: false
      t.integer :company_survey_series_id, null: false
      t.integer :giver_id, null: false
      t.string  :state, null: false
      t.datetime :next_due, null: false, default: '1970-01-01 00:00:00'
          # not :next_survey_due b/c survey is in the model name
      t.integer :next_survey_set_id, null: false
      t.datetime :last_reminded_at
      t.string :relationship_type, limit: 255
      t.string :relationship_tags, default: [], array: true
    end
    add_index :survey_plans, :user_role_id
    add_index :survey_plans, :company_survey_series_id
    add_index :survey_plans, :giver_id
    add_index :survey_plans, :state
    add_index :survey_plans, :last_reminded_at

    create_table :projects do |t|
      t.timestamps
      t.string :state, null: false, default: 'pending'
      t.integer :company_id
      t.string :name, limit: 255
      t.string :description
      t.date :start_date
      t.date :end_date
    end
    add_index :projects, :company_id
    add_index :projects, :name
    add_index :projects, :end_date

    create_table :user_roles do |t|
      t.timestamps
      t.integer :surveyable_id
      t.string :surveyable_type
      t.integer :user_id, null: false
      t.integer :role_id, null: false
    end
    add_index :user_roles, [:surveyable_id, :surveyable_type]
    add_index :user_roles, :user_id
    add_index :user_roles, :role_id

    create_table :roles do |t|
      t.timestamps
      t.string :name, null: false, limit: 255
      t.string :description
    end
    add_index :roles, :name

    # Point survey set at its parent survey series
    add_column :survey_sets, :survey_series_id, :integer
    add_index :survey_sets, :survey_series_id

    # Survey now belongs to SurveyPlan
    add_column :surveys, :survey_plan_id, :integer
    add_index :surveys, :survey_plan_id
    add_column :surveys, :parent_characteristic_id, :integer
    add_index :surveys, :parent_characteristic_id
    # TODO drop surveys.survey_set_id

    create_table :survey_series do |t|
      t.timestamps
      t.string :name, null: false, limit: 255
      t.string :description
      t.jsonb :default_config
    end
    add_index :survey_series, :name, unique: true

    create_table :company_survey_series do |t|
      t.timestamps
      t.integer :survey_series_id
      t.integer :company_id
      t.string :state, null: false, default: 'active'
      t.jsonb :config
    end
    add_index :company_survey_series, :survey_series_id
    add_index :company_survey_series, :company_id
    add_index :company_survey_series, :state
    add_index :company_survey_series, :config, using: :gin

    # Support multiple score types
    add_column :characteristics, :survey_name, :string, limit: 255
    add_column :characteristics, :parent_characteristic_id, :integer
    add_index :characteristics, :parent_characteristic_id

    # Denormalize PCID into SurveySeries for performance/convenience
    add_column :survey_series, :parent_characteristic_id, :integer
    add_index :survey_series, :parent_characteristic_id
  end
end
