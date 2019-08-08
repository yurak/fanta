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

ActiveRecord::Schema.define(version: 2019_08_08_133950) do

  create_table "clubs", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lineups", force: :cascade do |t|
    t.integer "team_id"
    t.integer "team_module_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tour_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "match_players", force: :cascade do |t|
    t.decimal "score"
    t.integer "player_id"
    t.integer "lineup_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "real_position"
    t.boolean "red_card", default: false
    t.boolean "yellow_card", default: false
    t.boolean "cleansheet", default: false
    t.decimal "goals", default: "0.0"
    t.decimal "missed_goals", default: "0.0"
    t.decimal "assits", default: "0.0"
    t.decimal "malus", default: "0.0"
    t.decimal "bonus", default: "0.0"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "tour_id", null: false
    t.bigint "host_id", null: false
    t.bigint "guest_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.integer "team_id"
    t.integer "club_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
  end

  create_table "players_positions", id: false, force: :cascade do |t|
    t.integer "player_id"
    t.integer "position_id"
  end

  create_table "positions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "slots", force: :cascade do |t|
    t.integer "number"
    t.string "position"
    t.integer "team_module_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "team_modules", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_teams_on_user_id"
  end

  create_table "tours", force: :cascade do |t|
    t.integer "number"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
