# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_sprockets_compass_session',
  :secret      => '0de3a957613e0f78e73d81ff6a1f1d4490c5654df38e8b8bed894c6e1ec2b19df2f3450abe354f7b98bf00628cf0a2f0f38c867bcc254b294fd475377c3385c6'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
