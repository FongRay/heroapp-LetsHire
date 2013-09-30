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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130930033739) do

  create_table "assessments", :force => true do |t|
    t.integer  "opening_candidate_id"
    t.text     "comment"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "assessments", ["opening_candidate_id"], :name => "index_assessments_on_opening_candidate_id"

  create_table "candidates", :force => true do |t|
    t.string   "name",                                         :null => false
    t.string   "email",                                        :null => false
    t.string   "phone"
    t.string   "source"
    t.text     "description"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "opening_candidates_count",     :default => 0
    t.integer  "status",                       :default => 0
    t.integer  "current_opening_candidate_id", :default => -1
    t.integer  "current_opening_id",           :default => -1
  end

  add_index "candidates", ["email"], :name => "index_candidates_on_email"
  add_index "candidates", ["name"], :name => "index_candidates_on_name"

  create_table "departments", :force => true do |t|
    t.string  "name",           :null => false
    t.string  "description"
    t.integer "openings_count"
  end

  add_index "departments", ["name"], :name => "index_departments_on_name", :unique => true

  create_table "interviewers", :force => true do |t|
    t.integer  "interview_id"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "interviewers", ["user_id", "interview_id"], :name => "index_interviewers_on_user_id_and_interview_id", :unique => true

  create_table "interviews", :force => true do |t|
    t.integer  "opening_candidate_id"
    t.string   "modality",                                      :null => false
    t.text     "description"
    t.string   "status",               :default => "scheduled"
    t.float    "score"
    t.text     "assessment"
    t.datetime "scheduled_at",                                  :null => false
    t.integer  "duration",             :default => 30
    t.string   "phone"
    t.string   "location"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  add_index "interviews", ["opening_candidate_id"], :name => "index_interviews_on_opening_candidate_id"

  create_table "opening_candidates", :force => true do |t|
    t.integer "opening_id"
    t.integer "candidate_id"
    t.integer "status",       :default => 1
    t.boolean "hold"
  end

  add_index "opening_candidates", ["opening_id", "candidate_id"], :name => "index_opening_candidates_on_opening_id_and_candidate_id", :unique => true

  create_table "opening_participants", :force => true do |t|
    t.integer "user_id"
    t.integer "opening_id"
  end

  add_index "opening_participants", ["user_id", "opening_id"], :name => "index_opening_participants_on_user_id_and_opening_id", :unique => true

  create_table "openings", :force => true do |t|
    t.string   "title"
    t.string   "country"
    t.string   "province"
    t.string   "city"
    t.integer  "department_id"
    t.integer  "hiring_manager_id"
    t.integer  "recruiter_id"
    t.text     "description"
    t.integer  "status",                   :default => 0
    t.integer  "creator_id"
    t.integer  "total_no",                 :default => 1
    t.integer  "filled_no",                :default => 0
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.integer  "opening_candidates_count", :default => 0
  end

  add_index "openings", ["creator_id"], :name => "index_openings_on_creator_id"
  add_index "openings", ["department_id"], :name => "index_openings_on_department_id"
  add_index "openings", ["hiring_manager_id"], :name => "index_openings_on_hiring_manager_id"
  add_index "openings", ["recruiter_id"], :name => "index_openings_on_recruiter_id"

  create_table "photos", :force => true do |t|
    t.integer  "interview_id"
    t.string   "name"
    t.string   "path"
    t.text     "description"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "resumes", :force => true do |t|
    t.integer  "candidate_id"
    t.string   "name"
    t.string   "path"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "settings", :force => true do |t|
    t.string   "ldap_host"
    t.integer  "ldap_port"
    t.string   "ldap_base"
    t.string   "smtp_server"
    t.integer  "smtp_port"
    t.string   "mail_user"
    t.string   "mail_password"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                :default => "",    :null => false
    t.string   "encrypted_password",   :default => "",    :null => false
    t.datetime "remember_created_at"
    t.string   "name"
    t.boolean  "admin",                :default => false, :null => false
    t.integer  "roles_mask",           :default => 1
    t.integer  "department_id"
    t.string   "authentication_token"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.datetime "deleted_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
