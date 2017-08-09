require 'sinatra/base'
require 'dotenv'
require 'rest-client'
require 'json'

module StreamAnalytics
  class Application < Sinatra::Application
    configure do
      Dotenv.load
    end

    get '/' do
      erb :index
    end

    get '/ping' do
      status 200
      json({ status: 'ok' })
    end

    post '/video' do
      video = youtube_api('videos', { id: params[:id], part: 'snippet,liveStreamingDetails' })
      video = video['items'][0]

      json({
        channel_name: video['snippet']['channelTitle'],
        live_chat_id: video['liveStreamingDetails']['activeLiveChatId'],
        stream_name: video['snippet']['title']
      })
    end

    get '/analytics' do
        next_page_token = ''
        page_count = 1
        messages = []
        api_params = { liveChatId: params[:live_chat_id], part: 'id, snippet, authorDetails' }

        # loop do
        #   break if page_count == 5

        #   if next_page_token && !next_page_token.empty?
        #     api_params[:pageToken] = next_page_token
        #   end

          messages_api = youtube_api('liveChat/messages', api_params)
          # break if messages_api['pageInfo']['totalResults'] == 0

          messages = messages_api['items'].map do |message|
            {
              author: message['authorDetails']['displayName'],
              content: message['snippet']['textMessageDetails']['messageText'],
              timestamp: message['snippet']['publishedAt']
            }
          end.concat(messages)

          # next_page_token = messages_api['nextPageToken']
          # break if !next_page_token || next_page_token.empty?
          # puts "NPT: #{next_page_token}"

          # puts "ENTERING SLEEP #{messages_api['pollingIntervalMillis']}"
          # sleep (messages_api['pollingIntervalMillis'] / 100)
          # puts "EXITING SLEEP"

          # page_count += 1
        # end

      users = messages.each_with_object(Hash.new(0)) do |message, counter|
        counter[message[:author]] += 1
      end.sort_by { |name, count| count }
        .reverse.map do |name, count|
        { content: name, count: count }
      end

      comments_per_s = messages.each_with_object(Hash.new(0)) do |message, counter|
      t = Time.parse(message[:timestamp])
      # rounded_t = t-t.sec #if you just want to round to remove the seconds

      # rounded_t = t-t.sec-t.min%1*60 #if you want to round to nearest minute
      nearest = 10
      rounded_t = t - t.sec%nearest
      rounded_t = rounded_t.to_s
      counter[rounded_t] +=1
      end.map do |time, count|
        {
          timestamp: time, count:count
        }
      end
      words = messages
        .map { |m| m[:content].downcase }
        .map { |c| c.split(' ') }.flatten
        .select{|w| ! stopwords.include? w}
        .group_by { |n| n }.values
        .sort { |a, b| b.length <=> a.length }
        .map { |a| { content: a[0], count: a.length } }

      json({
        messages: messages,
        users: users,
        words: words,
        comments_per_s: comments_per_s
      })
    end

    private

    def api_key
      ENV['YOUTUBE_API_KEY']
    end

    def json(data)
      content_type 'application/json'
      JSON.dump(data)
    end

    def youtube_api(path, params)
      JSON.parse(
        RestClient.get(
         "https://content.googleapis.com/youtube/v3/#{path}",
         { params: params.merge({ key: api_key }) }
        )
      )
    end
    def stopwords
      @_stopwords ||= JSON.parse(File.read("#{Dir.pwd}/lib/stream_analytics/stopwords.json"))
    end
  end
end
