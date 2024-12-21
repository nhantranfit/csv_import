# config/initializers/firsestore.rb

require 'google/cloud/firestore'

Google::Cloud::Firestore.configure do |config|
  config.project_id = ENV["PROJECT_FIRESTORE_ID"]
  config.credentials = ENV["FIREBASE_CREDENTIALS_PATH"] || ENV["FIREBASE_CREDENTIALS_JSON"]
end

FirestoreClient = Google::Cloud::Firestore.new
