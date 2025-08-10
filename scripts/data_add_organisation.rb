# Run with: bin/rails runner scripts/data_add_organisation.rb '{"name":"FooConf"}'
require_relative "../config/environment"
require "json"

payload = JSON.parse(ARGV[0] || $stdin.read)
result = DataTools.add_organisation!(payload)
puts result.to_json
