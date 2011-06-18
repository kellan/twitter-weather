require 'open-uri'
require 'rexml/document'
require 'md5'

class Weather
  attr_accessor :condition, :photo
  
  def self.check(rss)
    feed = self.feed_for_rss(rss)
    current = feed.elements.to_a("//yweather:condition")[0]
    forecast = feed.elements.to_a("//yweather:forecast")[0]
    unit = feed.elements["//yweather:units"].attributes["temperature"]
    wx = Weather.new
    wx.condition = "Today's weather: #{forecast.attributes["text"]}, Hi: #{forecast.attributes["high"]}#{unit}, Lo: #{forecast.attributes["low"]}#{unit} (Currently #{current.attributes["text"]}, #{current.attributes["temp"]}#{unit})"
    
    photo_id = current.attributes["code"]
    photo_url = "http://us.i1.yimg.com/us.yimg.com/i/us/we/52/#{photo_id}.gif"
    filename = "/tmp/weatherbot_#{photo_id}.gif"
    File.open(filename, "w+") { |f| f.write open(photo_url).read } unless File.exists?(filename)
    wx.photo = filename
    
    return wx
  end

  def self.feed_for_rss(rss)
    @@feeds ||= {}
    if @@feeds[rss] && @@feeds[rss][:last_checked] > Time.now - (60 * 10)
      return @@feeds[rss][:content]
    else
      @@feeds[rss] = {}
      @@feeds[rss][:last_checked] = Time.now
      return @@feeds[rss][:content] = REXML::Document.new(open(rss).read)
    end
  end
  
  def to_s
    condition
  end
end
