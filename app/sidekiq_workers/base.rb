Bundler.require
Dir[File.expand_path('../../../config/initializers/*.rb',__FILE__)].each{|file| require(file)}
Dir[File.expand_path('../../models/*.rb',__FILE__)].each {|file| require(file)}
ActiveRecord::Base.descendants.each {|model| model.connection}

module SidekiqWorkers
  class Base
    include Sidekiq::Worker

    sidekiq_retry_in do |count|
      5 * (count + 1) # 5, 10, 15, 20
    end

    def perform
      raise 'Not Implemented'
    end
  end
end
