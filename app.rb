require "sinatra"
require "dotenv/load"
require "faraday"
require "active_support"
require "active_support/core_ext"
require "active_support/cache"

CACHE = ActiveSupport::Cache::MemoryStore.new

ITEM_MAPPING = {
  migration: "Migration",
  users: "Users",
  files: "Files",
  dms: "DMs",
  mpdms: "Group DMs"
}

STATUS_MAPPING = {
  not_started: "Not started...",
  complete: "Complete!",
  paused: "Paused",
  scheduled: "Scheduled...",
  in_progress: "In progress..."
}.freeze

def humanize_item(item) = ITEM_MAPPING[item.to_sym] || item.humanize

def humanize_status(status) = STATUS_MAPPING[status.to_sym] || status.humanize

before do
  headers "X-Frame-Options" => "ALLOWALL"
  data = CACHE.fetch("migration_status", expires_in: 1.minute) { fetch_migration_data }
  @migration_data = data[:data]
  @last_updated = data[:updated]
  @icon_url = CACHE.fetch("icon", expires_in: 5.minutes) { fetch_icon }
end

get "/" do
  erb :index
end

def env!(key) = ENV[key] || (raise "please set #{key}!")

def xoxd_client
  @xoxd_client ||= Faraday.new("https://hackclub.enterprise.slack.com/api/") do |conn|
    conn.headers["cookie"] = "d=#{env!("SLACK_XOXD")}"

    conn.request :url_encoded
    conn.response :json
    conn.response :raise_error
  end
end

def xoxd_get(url, params = {}) = xoxd_client.get(url, params.merge({ token: env!("SLACK_XOXC") })).body

def fetch_migration_data = { data: xoxd_get("enterprise.migrations.getStatus", migration_id: env!("SLACK_MIGRATION_ID")), updated: Time.now }

def fetch_icon = Faraday.get("https://shrimp-shuffler.a.hackclub.dev/api/current").body
