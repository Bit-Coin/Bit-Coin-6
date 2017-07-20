# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170109084848) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "pg_stat_statements"

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.string   "mobile_phone",           limit: 255
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true, using: :btree
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree

  create_table "blogs", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.string   "author"
    t.string   "image"
    t.datetime "published_at"
    t.string   "state",        default: "active"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "characteristics", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255
    t.text     "description"
    t.text     "icon"
    t.string   "survey_name",              limit: 255
    t.integer  "parent_characteristic_id"
    t.string   "score_name"
  end

  add_index "characteristics", ["parent_characteristic_id"], name: "index_characteristics_on_parent_characteristic_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",       limit: 255, default: "draft", null: false
    t.integer  "receiver_id",                               null: false
    t.integer  "response_id"
    t.integer  "survey_id",                                 null: false
    t.string   "text",        limit: 255,                   null: false
    t.integer  "question_id"
  end

  add_index "comments", ["question_id"], name: "index_comments_on_question_id", using: :btree
  add_index "comments", ["receiver_id"], name: "index_comments_on_receiver_id", using: :btree
  add_index "comments", ["response_id"], name: "index_comments_on_response_id", using: :btree
  add_index "comments", ["state"], name: "index_comments_on_state", using: :btree
  add_index "comments", ["survey_id"], name: "index_comments_on_survey_id", using: :btree

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                       limit: 255,                   null: false
    t.integer  "manager_id"
    t.string   "encrypted_ripple_api_key",   limit: 255
    t.string   "encrypted_ripple_api_token", limit: 255
    t.string   "domain",                     limit: 255
    t.string   "type",                       limit: 255, default: "pilot", null: false
    t.string   "stub"
  end

  add_index "companies", ["domain"], name: "index_companies_on_domain", using: :btree
  add_index "companies", ["stub"], name: "index_companies_on_stub", using: :btree
  add_index "companies", ["type"], name: "index_companies_on_type", using: :btree

  create_table "company_survey_series", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "survey_series_id"
    t.integer  "company_id"
    t.string   "state",            default: "active", null: false
    t.jsonb    "config"
  end

  add_index "company_survey_series", ["company_id"], name: "index_company_survey_series_on_company_id", using: :btree
  add_index "company_survey_series", ["config"], name: "index_company_survey_series_on_config", using: :gin
  add_index "company_survey_series", ["state"], name: "index_company_survey_series_on_state", using: :btree
  add_index "company_survey_series", ["survey_series_id"], name: "index_company_survey_series_on_survey_series_id", using: :btree

  create_table "configurations", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "configurable_id",               null: false
    t.string   "configurable_type", limit: 255, null: false
    t.string   "key",               limit: 255, null: false
    t.string   "value",             limit: 255, null: false
  end

  add_index "configurations", ["configurable_id", "configurable_type"], name: "index_configurations_on_configurable_id_and_configurable_type", using: :btree
  add_index "configurations", ["key", "value"], name: "index_configurations_on_key_and_value", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "eventable_id"
    t.string   "eventable_type", limit: 255
    t.string   "note",           limit: 255
    t.string   "type",                       default: "",     null: false
    t.integer  "company_id"
    t.integer  "user_id"
    t.string   "severity",                   default: "info", null: false
    t.string   "name",                       default: "",     null: false
    t.jsonb    "body",                       default: {},     null: false
  end

  add_index "events", ["company_id"], name: "index_events_on_company_id", using: :btree
  add_index "events", ["eventable_id", "eventable_type"], name: "index_events_on_eventable_id_and_eventable_type", using: :btree
  add_index "events", ["name"], name: "index_events_on_name", using: :btree
  add_index "events", ["type"], name: "index_events_on_type", using: :btree
  add_index "events", ["user_id"], name: "index_events_on_user_id", using: :btree

  create_table "invitations", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "giver_id",                                                      null: false
    t.integer  "receiver_id",                                                   null: false
    t.string   "state",             limit: 255, default: "pending",             null: false
    t.datetime "hold_until",                    default: '1970-01-01 05:00:00', null: false
    t.datetime "reminded_at",                                                   null: false
    t.string   "relationship_type", limit: 255
    t.string   "relationship_tags",             default: [],                                 array: true
  end

  add_index "invitations", ["giver_id", "receiver_id"], name: "index_invitations_on_giver_id_and_receiver_id", unique: true, using: :btree
  add_index "invitations", ["giver_id"], name: "index_invitations_on_giver_id", using: :btree
  add_index "invitations", ["receiver_id"], name: "index_invitations_on_receiver_id", using: :btree
  add_index "invitations", ["relationship_tags"], name: "index_invitations_on_relationship_tags", using: :gin
  add_index "invitations", ["relationship_type"], name: "index_invitations_on_relationship_type", using: :btree
  add_index "invitations", ["reminded_at"], name: "index_invitations_on_reminded_at", using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "subscription_id"
    t.string   "stripe_invoice_id", limit: 255
    t.json     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices", ["company_id"], name: "index_invoices_on_company_id", using: :btree
  add_index "invoices", ["stripe_invoice_id"], name: "index_invoices_on_stripe_invoice_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "messageable_id"
    t.string   "messageable_type", limit: 255
    t.string   "to",               limit: 255
    t.string   "uuid",             limit: 255
    t.string   "sender",           limit: 255
    t.json     "original"
    t.string   "sg_message_id",    limit: 255
  end

  add_index "messages", ["messageable_id", "messageable_type"], name: "index_messages_on_messageable_id_and_messageable_type", using: :btree
  add_index "messages", ["sg_message_id"], name: "index_messages_on_sg_message_id", using: :btree
  add_index "messages", ["uuid"], name: "index_messages_on_uuid", using: :btree

  create_table "plans", force: :cascade do |t|
    t.string  "name",        limit: 255
    t.decimal "price"
    t.boolean "stripe_plan",             default: false, null: false
    t.string  "stripe_id",   limit: 255
    t.string  "interval",    limit: 255
    t.boolean "metered",                 default: false, null: false
    t.string  "description", limit: 255
  end

  create_table "programs", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "receiver_id"
    t.integer  "characteristic_id"
    t.text     "description"
  end

  add_index "programs", ["characteristic_id"], name: "index_programs_on_characteristic_id", using: :btree
  add_index "programs", ["receiver_id"], name: "index_programs_on_receiver_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                   default: "pending", null: false
    t.integer  "company_id"
    t.string   "name",        limit: 255
    t.string   "description"
    t.date     "start_date"
    t.date     "end_date"
  end

  add_index "projects", ["company_id"], name: "index_projects_on_company_id", using: :btree
  add_index "projects", ["end_date"], name: "index_projects_on_end_date", using: :btree
  add_index "projects", ["name"], name: "index_projects_on_name", using: :btree

  create_table "questions", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "characteristic_id"
    t.string   "other_phrased",     limit: 255
    t.string   "state",             limit: 255
    t.string   "self_phrased",      limit: 255
    t.integer  "response_set_id",               default: 1, null: false
  end

  add_index "questions", ["characteristic_id"], name: "index_questions_on_characteristic_id", using: :btree
  add_index "questions", ["response_set_id"], name: "index_questions_on_response_set_id", using: :btree
  add_index "questions", ["state"], name: "index_questions_on_state", using: :btree

  create_table "response_sets", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description", limit: 255,              null: false
    t.hstore   "values",                  default: {}, null: false
  end

  create_table "responses", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "question_id"
    t.integer  "characteristic_id"
    t.integer  "survey_id"
    t.integer  "score"
  end

  add_index "responses", ["characteristic_id"], name: "index_responses_on_characteristic_id", using: :btree
  add_index "responses", ["question_id"], name: "index_responses_on_question_id", using: :btree
  add_index "responses", ["survey_id"], name: "index_responses_on_survey_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",        limit: 255, null: false
    t.string   "description"
  end

  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "scores", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "receiver_id"
    t.integer  "characteristic_id"
    t.integer  "company_id"
    t.integer  "team_id"
    t.string   "cohort_name",       limit: 255
    t.datetime "published_at"
    t.string   "state",             limit: 255
    t.hstore   "stats"
    t.integer  "question_id"
  end

  add_index "scores", ["characteristic_id"], name: "index_scores_on_characteristic_id", using: :btree
  add_index "scores", ["cohort_name"], name: "index_scores_on_cohort_name", using: :btree
  add_index "scores", ["question_id"], name: "index_scores_on_question_id", using: :btree
  add_index "scores", ["receiver_id"], name: "index_scores_on_receiver_id", using: :btree
  add_index "scores", ["state"], name: "index_scores_on_state", using: :btree

  create_table "short_paths", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path",       limit: 255
    t.integer  "user_id"
  end

  add_index "short_paths", ["path"], name: "index_short_paths_on_path", using: :btree
  add_index "short_paths", ["user_id"], name: "index_short_paths_on_user_id", using: :btree

  create_table "subscription_users", force: :cascade do |t|
    t.integer  "subscription_id"
    t.integer  "user_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscription_users", ["subscription_id"], name: "index_subscription_users_on_subscription_id", using: :btree
  add_index "subscription_users", ["user_id"], name: "index_subscription_users_on_user_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "plan_id"
    t.integer  "owner_id"
    t.string   "state",                  limit: 255
    t.string   "stripe_token",           limit: 255
    t.string   "stripe_customer_id",     limit: 255
    t.string   "stripe_subscription_id", limit: 255
    t.datetime "start_at"
    t.datetime "end_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["company_id"], name: "index_subscriptions_on_company_id", using: :btree
  add_index "subscriptions", ["owner_id"], name: "index_subscriptions_on_owner_id", using: :btree
  add_index "subscriptions", ["plan_id"], name: "index_subscriptions_on_plan_id", using: :btree

  create_table "survey_plans", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_role_id",                                                         null: false
    t.integer  "company_survey_series_id",                                             null: false
    t.integer  "giver_id",                                                             null: false
    t.string   "state",                                                                null: false
    t.datetime "next_due",                             default: '1970-01-01 00:00:00', null: false
    t.integer  "next_survey_set_id",                                                   null: false
    t.datetime "last_reminded_at"
    t.string   "relationship_type",        limit: 255
    t.string   "relationship_tags",                    default: [],                                 array: true
  end

  add_index "survey_plans", ["company_survey_series_id"], name: "index_survey_plans_on_company_survey_series_id", using: :btree
  add_index "survey_plans", ["giver_id"], name: "index_survey_plans_on_giver_id", using: :btree
  add_index "survey_plans", ["last_reminded_at"], name: "index_survey_plans_on_last_reminded_at", using: :btree
  add_index "survey_plans", ["state"], name: "index_survey_plans_on_state", using: :btree
  add_index "survey_plans", ["user_role_id"], name: "index_survey_plans_on_user_role_id", using: :btree

  create_table "survey_series", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255, null: false
    t.string   "description"
    t.jsonb    "default_config"
    t.integer  "parent_characteristic_id"
  end

  add_index "survey_series", ["name"], name: "index_survey_series_on_name", unique: true, using: :btree
  add_index "survey_series", ["parent_characteristic_id"], name: "index_survey_series_on_parent_characteristic_id", using: :btree

  create_table "survey_set_questions", force: :cascade do |t|
    t.integer  "question_id"
    t.integer  "survey_set_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "survey_sets", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.integer  "position"
    t.string   "state",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "self_survey",                  default: false, null: false
    t.integer  "survey_series_id"
  end

  add_index "survey_sets", ["survey_series_id"], name: "index_survey_sets_on_survey_series_id", using: :btree

  create_table "surveys", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "receiver_id"
    t.integer  "giver_id"
    t.string   "state",                    limit: 255, default: "pending"
    t.datetime "completed_at"
    t.integer  "survey_set_id"
    t.integer  "survey_plan_id"
    t.integer  "parent_characteristic_id"
  end

  add_index "surveys", ["completed_at"], name: "index_surveys_on_completed_at", using: :btree
  add_index "surveys", ["giver_id"], name: "index_surveys_on_giver_id", using: :btree
  add_index "surveys", ["parent_characteristic_id"], name: "index_surveys_on_parent_characteristic_id", using: :btree
  add_index "surveys", ["receiver_id"], name: "index_surveys_on_receiver_id", using: :btree
  add_index "surveys", ["state"], name: "index_surveys_on_state", using: :btree
  add_index "surveys", ["survey_plan_id"], name: "index_surveys_on_survey_plan_id", using: :btree
  add_index "surveys", ["survey_set_id"], name: "index_surveys_on_survey_set_id", using: :btree

  create_table "team_members", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "user_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "is_manager", default: false
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.integer  "company_id"
    t.integer  "manager_id"
  end

  add_index "teams", ["company_id"], name: "index_teams_on_company_id", using: :btree

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "surveyable_id"
    t.string   "surveyable_type"
    t.integer  "user_id",         null: false
    t.integer  "role_id",         null: false
  end

  add_index "user_roles", ["role_id"], name: "index_user_roles_on_role_id", using: :btree
  add_index "user_roles", ["surveyable_id", "surveyable_type"], name: "index_user_roles_on_surveyable_id_and_surveyable_type", using: :btree
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_id"
    t.string   "first_name",               limit: 255
    t.string   "last_name",                limit: 255
    t.string   "mobile_phone",             limit: 255
    t.date     "hire_date"
    t.string   "gender",                   limit: 255
    t.string   "race_ethnicity",           limit: 255
    t.date     "birthdate"
    t.string   "email",                    limit: 255, default: "",                                                                                                                                   null: false
    t.string   "encrypted_password",       limit: 255, default: "",                                                                                                                                   null: false
    t.string   "reset_password_token",     limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0,                                                                                                                                    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.integer  "team_id"
    t.string   "cohort",                   limit: 255
    t.string   "title",                    limit: 255
    t.string   "authentication_token",     limit: 255
    t.hstore   "options"
    t.string   "confirmation_token",       limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",        limit: 255
    t.datetime "unsubscribed_at"
    t.string   "state",                    limit: 255, default: "active",                                                                                                                             null: false
    t.integer  "proxy_id"
    t.string   "proxy_secret",             limit: 255
    t.string   "tags",                                 default: [],                                                                                                                                                array: true
    t.datetime "last_reminded_at",                     default: '1970-01-01 00:00:00',                                                                                                                null: false
    t.string   "type",                     limit: 255, default: "prospect",                                                                                                                           null: false
    t.date     "start_date"
    t.string   "department"
    t.string   "sex"
    t.integer  "age"
    t.integer  "bad_password_count",                   default: 0,                                                                                                                                    null: false
    t.integer  "reset_password_count",                 default: 0,                                                                                                                                    null: false
    t.boolean  "access_development_tools",             default: false
    t.hstore   "development_tools_info",               default: {"curious"=>"0", "committed"=>"0", "executive"=>"0", "consistent"=>"0", "management"=>"0", "cooperative"=>"0", "conscientious"=>"0"}
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["cohort"], name: "index_users_on_cohort", using: :btree
  add_index "users", ["company_id"], name: "index_users_on_company_id", using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email", "company_id"], name: "index_users_on_email_and_company_id", unique: true, using: :btree
  add_index "users", ["last_reminded_at"], name: "index_users_on_last_reminded_at", using: :btree
  add_index "users", ["proxy_id"], name: "index_users_on_proxy_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["state"], name: "index_users_on_state", using: :btree
  add_index "users", ["tags"], name: "index_users_on_tags", using: :gin
  add_index "users", ["team_id"], name: "index_users_on_team_id", using: :btree

end
