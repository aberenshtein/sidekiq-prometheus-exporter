# frozen_string_literal: true

require 'sidekiq'

class SleepyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :sleepy

  def perform(args)
    time = args.fetch('time') { rand(1..3) }.to_i
    sleep time
  end
end

class BrokenWorker
  include Sidekiq::Worker

  sidekiq_options queue: :broken,
                  retry: 5

  def perform
    raise 'Ooooooops ...'
  end
end

class NormalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(args)
    sleep rand(0..0.5) + 0.5
  end
end

Sidekiq.configure_server do |config|
  config.redis = {url: 'redis://redis:6379/0'}
end

Sidekiq.configure_client do |config|
  config.redis = {url: 'redis://redis:6379/0'}
end
