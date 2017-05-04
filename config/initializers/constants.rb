DB_CONFIG = YAML.load_file(File.expand_path('../../../db/config.yml', __FILE__))[(ENV['RACK_ENV']||'development')]
SIDEKIQ_CONFIG = YAML.load_file(File.expand_path('../../redis.yml', __FILE__))[(ENV['RACK_ENV']||'development')]
