# Run with: bin/rails runner scripts/data_add_video.rb org-slug event-slug '{"title":"Talk","event_name":"MyConf 2025"}'
require_relative "../config/environment"
require "json"

org = ARGV[0] or abort("usage: org-slug event-slug JSON")
event = ARGV[1] or abort("usage: org-slug event-slug JSON")
payload = JSON.parse(ARGV[2] || $stdin.read)
result = DataTools.add_video!(organisation_slug: org, event_slug: event, attributes: payload)
puts result.to_json
