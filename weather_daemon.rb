require 'rubygems'
require 'weather_bot'
require 'yaml'
require 'xmpp4r-simple'
require 'daemons'

class WeatherDaemon
  def initialize
    config = YAML.load(File.read("config"))
    @weather_bots = []
    config.each do |bot|
      @weather_bots << WeatherBot.new(*bot)
    end
  end

  def start
    loop do
      send_updates
      respond_to_nudge
      sleep 1
    end
  end

  def send_updates
    weather_bots.each { |weather_bot| weather_bot.send_when_ready }
  end

  def respond_to_nudge
    # empty for now
  end

  def weather_bots
    @weather_bots
  end
end

options = {
  :backtrace => true,
  :dir_mode => :system
}

daemon = WeatherDaemon.new
Daemons.run_proc('WeatherDaemon', options) { daemon.start }
