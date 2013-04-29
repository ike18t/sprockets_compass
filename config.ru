# we need to protect against multiple includes of the Rails environment (trust me)
require File.dirname(__FILE__) + '/config/environment' if !defined?(Rails) || !Rails.initialized?
require 'sprockets'

if RAILS_ENV == 'development'
  map '/assets' do
    run Sprockets.env
  end
end

map '/' do
  run ActionController::Dispatcher.new
end
