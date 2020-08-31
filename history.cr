require "http/client"
require "json"

def get_user(id, cache)
        return cache[id] if cache[id]?

        res = HTTP::Client.get("https://slack.com/api/users.info?token=#{ENV["TOKEN"]}&user=#{id}")
        res_json = JSON.parse res.body
        cache[id] = res_json
        res_json
end

def get_channel_history (id)
        res = HTTP::Client.get("https://slack.com/api/conversations.history?token=#{ENV["TOKEN"]}&channel=#{id}")
        JSON.parse res.body
end

def get_replies (id, ts)
        res = HTTP::Client.get("https://slack.com/api/conversations.replies?token=#{ENV["TOKEN"]}&channel=#{id}&ts=#{ts}")
        JSON.parse res.body
end

def get_message_text (msg)
if msg["files"]?
                msg["files"].as_a.map(&.["url_private"].as_s).join("\n")
        else
                msg["text"]
        end
end

history_res = get_channel_history(ARGV.first)

messages = [] of String
user_cache = {} of String => JSON::Any

history_res["messages"].as_a.each do |msg|
        user = get_user(msg["user"].as_s, user_cache)
        messages.unshift "#{Time::UNIX_EPOCH + (msg["ts"].as_s.to_f32.seconds)} - #{user["user"]["name"]} - #{get_message_text msg}"
        if msg["reply_count"]?
                replies = [] of String
                reply_res = get_replies(ARGV.first, msg["ts"].as_s)
                reply_res["messages"].as_a[1..].each do |msg|
                        user = get_user(msg["user"].as_s, user_cache)
                        replies << "| #{Time::UNIX_EPOCH + (msg["ts"].as_s.to_f32.seconds)} - #{user["user"]["name"]} - #{get_message_text msg}"
                end
                messages = [ messages[0] ] + replies + messages[1...]
        end
end

puts messages.join "\n"
