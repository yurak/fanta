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

ActiveRecord::Schema.define(version: 2020_10_04_213511) do

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.string "summary"
    t.string "description"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clubs", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tournament_id"
    t.integer "status", default: 0, null: false
    t.string "full_name", default: "", null: false
    t.index ["tournament_id"], name: "index_clubs_on_tournament_id"
  end

  create_table "join_requests", force: :cascade do |t|
    t.string "username", default: "", null: false
    t.string "contact", default: "", null: false
    t.string "email"
    t.string "leagues"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "leagues", force: :cascade do |t|
    t.string "name"
    t.bigint "tournament_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tour_difference", default: 0, null: false
    t.integer "season_id"
    t.decimal "min_avg_def_score", default: "6.0", null: false
    t.decimal "max_avg_def_score", default: "7.0", null: false
    t.boolean "custom_bonuses", default: false, null: false
    t.decimal "missed_goals", default: "2.0", null: false
    t.decimal "failed_penalty", default: "3.0", null: false
    t.boolean "recount_goals", default: false, null: false
    t.index ["season_id"], name: "index_leagues_on_season_id"
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
    t.integer "league_id"
    t.index ["league_id"], name: "index_links_on_league_id"
  end

  create_table "match_players", force: :cascade do |t|
    t.integer "lineup_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "real_position"
    t.boolean "cleansheet", default: false
    t.decimal "position_malus", default: "0.0"
    t.integer "subs_status", default: 0, null: false
    t.integer "round_player_id"
    t.index ["round_player_id"], name: "index_match_players_on_round_player_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "tour_id", null: false
    t.bigint "host_id", null: false
    t.bigint "guest_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "player_positions", force: :cascade do |t|
    t.integer "player_id"
    t.integer "position_id"
    t.index ["player_id", "position_id"], name: "player_position"
  end

  create_table "player_teams", force: :cascade do |t|
    t.integer "player_id"
    t.integer "team_id"
    t.index ["player_id"], name: "index_player_teams_on_player_id"
    t.index ["team_id"], name: "index_player_teams_on_team_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.integer "club_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.string "first_name"
    t.string "nationality"
    t.string "tm_url"
    t.string "pseudonym", default: "", null: false
  end

  create_table "positions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "results", force: :cascade do |t|
    t.integer "team_id"
    t.integer "points", default: 0, null: false
    t.integer "scored_goals", default: 0, null: false
    t.integer "missed_goals", default: 0, null: false
    t.integer "wins", default: 0, null: false
    t.integer "draws", default: 0, null: false
    t.integer "loses", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "league_id"
    t.index ["league_id"], name: "index_results_on_league_id"
    t.index ["team_id"], name: "index_results_on_team_id"
  end

  create_table "round_players", force: :cascade do |t|
    t.integer "tournament_round_id"
    t.integer "player_id"
    t.decimal "score", precision: 4, scale: 2, default: "0.0"
    t.decimal "goals", default: "0.0"
    t.decimal "missed_goals", default: "0.0"
    t.decimal "assists", default: "0.0"
    t.decimal "missed_penalty", default: "0.0"
    t.decimal "scored_penalty", default: "0.0"
    t.decimal "caught_penalty", default: "0.0"
    t.decimal "failed_penalty", default: "0.0"
    t.boolean "yellow_card", default: false
    t.boolean "red_card", default: false
    t.decimal "own_goals", default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_round_players_on_player_id"
    t.index ["tournament_round_id"], name: "index_round_players_on_tournament_round_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.integer "start_year"
    t.integer "end_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "slots", force: :cascade do |t|
    t.integer "number"
    t.string "position"
    t.integer "team_module_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location", default: "", null: false
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
    t.integer "league_id"
    t.string "code", default: "", null: false
    t.string "human_name", default: "", null: false
    t.index ["league_id"], name: "index_teams_on_league_id"
    t.index ["user_id"], name: "index_teams_on_user_id"
  end

  create_table "tournament_matches", force: :cascade do |t|
    t.integer "tournament_round_id"
    t.bigint "host_club_id", null: false
    t.bigint "guest_club_id", null: false
    t.integer "host_score"
    t.integer "guest_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_round_id"], name: "index_tournament_matches_on_tournament_round_id"
  end

  create_table "tournament_rounds", force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "season_id"
    t.integer "number"
    t.integer "status", default: 0
    t.datetime "start_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id"], name: "index_tournament_rounds_on_season_id"
    t.index ["tournament_id"], name: "index_tournament_rounds_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tours", force: :cascade do |t|
    t.integer "number"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deadline"
    t.integer "league_id"
    t.integer "tournament_round_id"
    t.index ["league_id"], name: "index_tours_on_league_id"
    t.index ["tournament_round_id"], name: "index_tours_on_tournament_round_id"
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
    t.decimal "summer_balance", default: "0.0"
    t.string "name", default: "", null: false
    t.integer "active_team_id"
    t.boolean "notifications", default: false, null: false
    t.string "avatar", default: "1", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
