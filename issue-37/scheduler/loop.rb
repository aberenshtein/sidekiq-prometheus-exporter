# frozen_string_literal: true

require 'sidekiq'

class SleepyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sleepy
end

class BrokenWorker
  include Sidekiq::Worker
  sidekiq_options queue: :broken, retry: 5
end

class NormalWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default
end

Sidekiq.configure_server do |config|
  config.redis = {url: 'redis://redis:6379/0'}
end

Sidekiq.configure_client do |config|
  config.redis = {url: 'redis://redis:6379/0'}
end

# -------------------------------------------------------------------------------

module NormalWorkerArgs
  module_function

  def args
    {
      "data" => [
        {
          "id" => "DEBERCBS-#{rand 1..1_000_000}",
          "type" => "stations-#{rand 1..1_000_000}",
          "attributes" => {
            "station_type" => "bus_station-#{rand 1..1_000_000}",
            "code" => "DEBERCBS-#{rand 1..1_000_000}",
            "name" => "Berlin Central Bus Station",
            "longitude" => 13.279692,
            "latitude" => 52.507589,
            "street_and_number" => "Masurenallee 4-6",
            "zip_code" => "14057-#{rand 1..1_000_000}",
            "time_zone" => "Europe/Berlin-#{rand 1..1_000_000}",
            "description" => "The Berlin Central Bus Station is located close to the S-Bahn Station (lines S41, S42 and S46)--#{rand 1..1_000_000}"
          },
          "relationships" => {
            "area" => {"data" => nil},
            "city" => {"data" => {"type"=>"cities", "id" => "DEBER-#{rand 1..1_000_000}"}}
          }
        }
      ],
      "included" => [
        {
          "id" => "DEBER",
          "type" => "cities",
          "attributes" => {"code" => "DEBER", "name" => "Berlin-#{rand 1..1_000_000}"}
        }
      ],
      "jsonapi" => {"version" => "1.#{rand 1...1_000_000}"}
    }
  end
end

STDOUT.sync = true

require 'logger'
logger = Logger.new(STDOUT, level: Logger::DEBUG)

loop do
  BrokenWorker.perform_async

  if rand(1..100) + 35 < 50
    sleepy = 5
    logger.debug("Schedule #{sleepy} SleepyWorkers")

    sleepy.times { SleepyWorker.perform_async(time: rand(60..600)) }
  end

  normal = rand 3_000..10_000
  logger.debug("Schedule #{normal} NormalWorkers")

  normal.times do
    if rand(1..100) + 1 < 50
      NormalWorker.perform_async(NormalWorkerArgs.args)
    else
      NormalWorker.set(queue: :random).perform_async(NormalWorkerArgs.args)
    end
  end

  sleep rand(15..30)
end
