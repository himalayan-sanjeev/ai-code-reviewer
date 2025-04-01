require 'net/http'
require 'json'
require 'uri'
require 'open3'

# Get the code from the PR files
pr_files = ARGV[0]

# Run RuboCop for code style checks
rubocop_output, _stderr, _status = Open3.capture3("rubocop --format json")

# Extract relevant RuboCop offenses
rubocop_issues = JSON.parse(rubocop_output)["files"].map do |file|
  file["offenses"].map { |offense| "#{file['path']} - #{offense['message']}" }
end.flatten.join("\n")

# Gemini API Endpoint
gemini_url = "https://generativelanguage.googleapis.com/v1beta2/models/gemini-2:generateText"
api_key = ENV['GEMINI_API_KEY']

# Prepare the code for analysis
code = pr_files

# Create the body for the request
uri = URI(gemini_url)
headers = {
  'Content-Type' => 'application/json',
  'Authorization' => "Bearer #{api_key}"
}

body = {
  prompt: <<~PROMPT,
    Review this code for style, performance, and security issues. Make sure it follows **best Rails development practices**:
    1. **RuboCop Output** (style violations):
    #{rubocop_issues}

    2. **Code Analysis**:
    #{code}

    3. **Rails Best Practices**:
    - Use of `find_by` instead of `where(...).first` for single records.
    - Avoid N+1 queries; check eager loading with `includes`.
    - Proper usage of ActiveRecord scopes.
    - Keep controllers thin, extract logic to service objects or concerns.
    - Make use of strong parameters in controllers for security.
  PROMPT
  temperature: 0.7,
  maxOutputTokens: 500
}.to_json

# Send the request to Gemini API
response = Net::HTTP.post(uri, body, headers)

# Parse the response
response_json = JSON.parse(response.body)
review_feedback = response_json["candidates"]&.first&.dig("content") || "No review feedback from Gemini."

# Save the response to a file so we can post it to the PR
File.open('gemini_feedback.txt', 'w') do |file|
  file.puts review_feedback
end
