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

ActiveRecord::Schema.define(version: 20140520142235) do

  create_table "calendars", force: true do |t|
    t.string   "calid",      null: false
    t.string   "calendar",   null: false
    t.string   "etag",       null: false
    t.string   "timezone",   null: false
    t.string   "bgcolor",    null: false
    t.string   "fgcolor",    null: false
    t.string   "accessrole", null: false
    t.string   "user_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", force: true do |t|
    t.string   "event_id",      null: false
    t.string   "event",         null: false
    t.string   "start",         null: false
    t.string   "end",           null: false
    t.string   "status",        null: false
    t.string   "etag",          null: false
    t.string   "link",          null: false
    t.string   "event_created", null: false
    t.string   "event_updated", null: false
    t.string   "user_id",       null: false
    t.string   "calendar_id",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "uid",           null: false
    t.string   "name",          null: false
    t.string   "token",         null: false
    t.string   "refresh_token", null: false
    t.integer  "expires_at",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
