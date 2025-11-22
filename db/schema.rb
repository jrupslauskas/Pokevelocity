# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_22_020849) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "captures", force: :cascade do |t|
    t.string "ball_type", null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.integer "pokemon_id", null: false
    t.integer "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["pokemon_id"], name: "index_captures_on_pokemon_id"
    t.index ["trainer_id", "pokemon_id"], name: "index_captures_on_trainer_id_and_pokemon_id", unique: true
    t.index ["trainer_id"], name: "index_captures_on_trainer_id"
  end

  create_table "pokemons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "difficulty", default: 3, null: false
    t.string "name", null: false
    t.integer "pokedex_number", null: false
    t.datetime "updated_at", null: false
    t.index ["pokedex_number"], name: "index_pokemons_on_pokedex_number", unique: true
  end

  create_table "route_encounters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "pokemon_id", null: false
    t.bigint "route_id", null: false
    t.integer "spawn_rate"
    t.datetime "updated_at", null: false
    t.index ["pokemon_id"], name: "index_route_encounters_on_pokemon_id"
    t.index ["route_id"], name: "index_route_encounters_on_route_id"
  end

  create_table "routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "trainers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "great_balls_count", default: 0, null: false
    t.integer "icon_pokemon_id"
    t.integer "master_balls_count", default: 0, null: false
    t.string "password_digest", null: false
    t.integer "pokeballs_count", default: 0, null: false
    t.integer "ultra_balls_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_trainers_on_username", unique: true
  end

  create_table "validation_codes", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.check_constraint "length(code::text) = 6", name: "validation_code_length_check"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "captures", "pokemons"
  add_foreign_key "captures", "trainers"
  add_foreign_key "route_encounters", "pokemons"
  add_foreign_key "route_encounters", "routes"
end
