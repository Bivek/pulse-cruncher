ENV['RACK_ENV'] ||= 'development'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)
Dir["#{File.dirname(__FILE__)}/config/initializers/*.rb"].each {|file| require(file)}
Dir["#{File.dirname(__FILE__)}/app/models/*.rb"].each {|file| require(file)}
Dir["#{File.dirname(__FILE__)}/app/sidekiq_workers/*.rb"].each {|file| require(file)}
ActiveRecord::Base.descendants.each {|model| model.connection}