require_relative 'bot.rb'
require 'twitter'

client = Twitter::REST::Client.new do |config|
  config.consumer_key    = ENV['TW_KEY']
  config.consumer_secret = ENV['TW_SECRET']
  config.bearer_token    = ENV['TW_TOKEN']
end

Bot.new(client)