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

ActiveRecord::Schema.define(version: 20150418134516) do

  create_table "accounts", force: :cascade do |t|
    t.string   "company_name"
    t.string   "qb_token"
    t.string   "qb_secret"
    t.string   "qb_company_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "email"
    t.string   "phone"
    t.string   "mobile"
    t.string   "address_1"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "qbo_id"
  end

  create_table "qbo_errors", force: :cascade do |t|
    t.string   "message"
    t.text     "body"
    t.string   "resource_type", limit: 100
    t.integer  "resource_id"
    t.text     "request_xml"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

end
