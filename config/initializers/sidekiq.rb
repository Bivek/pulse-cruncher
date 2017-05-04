require_relative './constants'
require 'resolv-replace'


sidekiq_db = SIDEKIQ_CONFIG['db'] || 0
host = SIDEKIQ_CONFIG['host']
port = SIDEKIQ_CONFIG['port']

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{host}:#{port}/#{sidekiq_db}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{host}:#{port}/#{sidekiq_db}", size: 1 }
end

Sidekiq.default_worker_options = { queue: 'default', backtrace: true, retry: 5 }