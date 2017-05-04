source 'http://rubygems.org'
ruby File.read('.ruby-version').match(/\S*/).to_s


#database adapter
gem 'activerecord'
gem 'pg'
gem 'sidekiq'

#database migration
gem 'standalone_migrations'


group :development do
  #for debugging
  gem 'pry'
  gem 'pry-nav'
end

group :test do
  gem 'rspec'
  gem 'database_cleaner'
end