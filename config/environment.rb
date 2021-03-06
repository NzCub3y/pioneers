RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

require "set"

Rails::Initializer.run do |config|
  config.gem "authlogic"
  config.gem "compass"
  config.gem "haml"
  config.gem "json"
  config.gem "acts_as_list"
  config.gem "sprockets"
  config.gem "state_machine"

  config.time_zone = 'UTC'
end
