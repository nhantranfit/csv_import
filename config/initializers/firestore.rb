# config/initializers/firsestore.rb

require 'google/cloud/firestore'

Google::Cloud::Firestore.configure do |config|
  config.project_id = ENV["PROJECT_FIRESTORE_ID"]
  config.credentials = Rails.root.join(ENV["FIREBASE_CREDENTIALS_PATH"]).to_s
end

FirestoreClient = Google::Cloud::Firestore.new
