# Run with: bin/rails runner scripts/data_add_speaker.rb '{"name":"Jane Doe"}'
require_relative "../config/environment"
require "json"

payload = JSON.parse(ARGV[0] || $stdin.read)
result = DataTools.add_speaker!(payload)
puts result.to_json
