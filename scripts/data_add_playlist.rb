# Run with: bin/rails runner scripts/data_add_playlist.rb org-slug '{"title":"My Event 2025"}'
require_relative "../config/environment"
require "json"

org = ARGV[0] or abort("usage: org-slug JSON")
payload = JSON.parse(ARGV[1] || $stdin.read)
result = DataTools.add_or_update_playlist!(organisation_slug: org, attributes: payload)
puts result.to_json
