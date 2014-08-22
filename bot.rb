# This bot reply "Yes", "No" or "Maybe" for tweets with questions
# Just config this script with your OAuth keys and execute it (for tokens check apps.twitter.com)

# Also make sure to install these gems
require "rubygems"
require "tweetstream"
require "em-http-request"
require "simple_oauth"
require "json"
require "uri"

$stdout.sync = true

# config oauth
OAUTH = {
 :consumer_key => "depn6AeXwy1uFCQSYvOKBWx4P",
 :consumer_secret => "sJ8CuTqBW2XAm5s2n66CAC76GOpG0Pwoj36cIKGplrxsUDkVdx",
 :token => "126495259-AIoK9aW7tU7A03lGUeveSbcaHhDPIF1cblKGGmrl",
 :token_secret => "18R0H4LWKDoVoIXqvc6F5JaFsxbSzoy6yfJMdHLVAFpnr"
}
ACCOUNT_ID = OAUTH[:126495259].split("-").first.to_i
 

TweetStream.configure do |config|
  config.consumer_key       = OAUTH[:consumer_key]
  config.consumer_secret    = OAUTH[:consumer_secret]
  config.oauth_token        = OAUTH[:token]
  config.oauth_token_secret = OAUTH[:token_secret]
  config.auth_method = :oauth
end

@client  = TweetStream::Client.new

@client.on_error do |message|
  puts "[STREAM_ERROR] #{message}"
end
@client.on_enhance_your_calm do
  puts "[CALM_DOWN]"
end
@client.on_limit do |skip_count|
  puts "[STREAM_LIMIT] You lost #{skip_count} tweets"
end
@client.on_friends do |friends|
  puts "[FRIENDS] You have #{friends.size} friends. Now tracking..."
end

puts "[STARTING] bot..."
@client.userstream() do |status|

  if !status.retweet? &&                                                          # isn't retweet
     status.in_reply_to_user_id? && status.in_reply_to_user_id == ACCOUNT_ID &&   # is replying to your user
     status.text[-1] == "?"                                                       # is a question

      tweet = {
        "status" => "@#{status.user.screen_name} " + %w(Yes No Maybe).sample, 
        "in_reply_to_status_id" => status.id.to_s 
      }

      # posting reply to Twitter
      twurl = URI.parse("https://api.twitter.com/1.1/statuses/update.json")
      authorization = SimpleOAuth::Header.new(:post, twurl.to_s, tweet, OAUTH)

      http = EventMachine::HttpRequest.new(twurl.to_s).post({
        :head => {"Authorization" => authorization},
        :body => tweet
      })
      http.errback {
        puts "[CONN_ERROR] errback"
      }
      http.callback {
        if http.response_header.status.to_i == 200
          puts "[HTTP_OK] #{http.response_header.status}"
        else
          puts "[HTTP_ERROR] #{http.response_header.status}"
        end
      }

  end

end
