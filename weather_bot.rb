require 'xmpp4r-simple'
require 'weather'
require 'cgi'
require 'net/http'

class WeatherBot
  def initialize(jid, password, weather_rss, time_to_send, screen_name=nil)
    @jid = jid
    @password = password
    @weather_rss = weather_rss
    @time_to_send = time_to_send
    @last_update = 0
    @last_send = 0
    @screen_name = screen_name
  end

  def send_when_ready
    update_status
    if weather && ready?
      puts "[#{Time.now}] #{@jid}: I think I'm ready to send a weather update."
      jabber.deliver("twitter@twitter.com", weather.to_s) 
      #update_twitter_buddy_icon_exec(weather) if @screen_name
      @last_send = now.to_i
    end
    
  end

  private

  # this relies on undocumented features of twitter, not for public consumption.
  # twitter will release an improved "user settings" api in early 2007.

  def update_twitter_buddy_icon_exec(weather)
    cmd = "curl -F \"username=#{@screen_name}\" -F \"user[profile_image]=@#{weather.photo}\" -F \"sekret=#{sekret}\" http://twitter.com/account/picture_sekret"
    puts "attempting to upload: #{cmd}"
    `#{cmd}`
  end
  
  def now
    Time.now.getutc
  end

  def ready?
    @time_to_send.each do |tts|
      return false if @last_send > (Time.now.to_i - 900)
      return true if now.hour == tts[0].to_i && now.min == tts[1].to_i
    end
    false
  end

  def weather
    # at some point this should retry until it gets fresh weather, or die / log.
    @weather
  end

  def update_status
    return false if @last_update > (Time.now.to_i - 900)
    begin
      @weather = Weather.check(@weather_rss)
      puts "[#{Time.now}] #{@jid} Updating status"
      jabber.status(:chat, weather.to_s)
      @last_update = Time.now.to_i
      update_twitter_buddy_icon_exec(weather) if @screen_name
      return true
    rescue Exception => ex
      puts "failed to fetch #{@weather_rss}: " + ex
      return false
    end
  end

  def jabber
    begin
      puts "[#{Time.now}] #{@jid}: Connecting to Jabber" unless @jabber
      @jabber ||= Jabber::Simple.new(@jid, @password, :chat, "Updating Soon.")
    rescue
      puts "Couldn't connect to #{@jid}"
    end
    @jabber
  end
end
