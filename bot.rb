require 'telegram/bot'
require 'down'

class Bot
  TOKEN = ENV['TG_BOT_SECRET']
  
  MEDIA_TYPES = %(photo animated_gif video)
  
  def save_to_tempfile(url)
    ::Down.download(url)
  end

  def get_tweet_id(tweet_url)
    tweet_url&.split('/')[5] rescue nil
  end

  def send_bot_error(bot, message, text = "Invalid link, please provide valid direct Tweet URL")
    bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def process_photo(media, bot, message)
    url = media.media_url.to_s
    tf = save_to_tempfile(url)
    bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new(tf.path, 'image/jpeg'))
  end

  def process_animated_gif(media, bot, message)
    url = media&.video_info.variants.first.url.to_s
    tf = save_to_tempfile(url)
    bot.api.send_animation(chat_id: message.chat.id, animation: Faraday::UploadIO.new(tf.path, 'image/gif'))
  end

  def process_video(media, bot, message)
    url = media&.video_info.variants.first.url.to_s
    tf = save_to_tempfile(url)
    bot.api.send_video(chat_id: message.chat.id, video: Faraday::UploadIO.new(tf.path, 'video/mp4'))
  end

  def initialize(client)
    Telegram::Bot::Client.run(TOKEN) do |bot|
      bot.listen do |message|
        case message.text
        when /^https?:\/\/twitter\.com\/(?:#!\/)?(\w+)\/status(es)?\/(\d+)/
          tid = get_tweet_id(message.text)
          if tid
            begin
              status = client.status(tid, tweet_mode: 'extended')
              bot.api.send_message(chat_id: message.chat.id, text: "Please wait, doing my job...", disable_web_page_preview: true)
              status.media.each do |media|
                if MEDIA_TYPES.include?(media.type)
                  case media.type
                  when 'photo'
                    process_photo(media, bot, message)
                  when 'animated_gif'
                    process_animated_gif(media, bot, message)
                  when 'video'
                    process_video(media, bot, message)
                  end
                end
              end
            rescue Exception => e
              send_bot_error(bot, message, "Tweet not found, please check your Tweet URL")
            end
          else
            send_bot_error(bot, message)
          end
        else
          send_bot_error(bot, message)
        end
      end
    end
  end
end