require 'sinatra/base'
require 'rest-client'

module StreamAnalytics
  class Application < Sinatra::Application
    get '/' do
      # JSON.parse(RestClient.post('localhost:3000/video', { id: 'fMvVr2jCQXU' }))
      erb :index
    end

    post '/video' do
      video = youtube_api('videos', { id: params[:id], part: 'snippet,liveStreamingDetails' })
      video = video['items'][0]
      @live_chat_id = video['liveStreamingDetails']['activeLiveChatId']
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

      loop do
        break if page_count == 5

        if next_page_token && !next_page_token.empty?
          api_params[:pageToken] = next_page_token
        end

        messages_api = youtube_api('liveChat/messages', api_params)
        break if messages_api['pageInfo']['totalResults'] == 0

        messages = messages_api['items'].map do |message|
          {
            author: message['authorDetails']['displayName'],
            content: message['snippet']['textMessageDetails']['messageText'],
            timestamp: message['snippet']['publishedAt']
          }
        end.concat(messages)

        next_page_token = messages_api['nextPageToken']
        break if !next_page_token || next_page_token.empty?
        puts "NPT: #{next_page_token}"

        puts "ENTERING SLEEP #{messages_api['pollingIntervalMillis']}"
        sleep (messages_api['pollingIntervalMillis'] / 100)
        puts "EXITING SLEEP"

        page_count += 1
      end

      users = messages.each_with_object(Hash.new(0)) do |message, counter|
        counter[message[:author]] += 1
      end.sort_by { |name, count| count }
        .reverse.map do |name, count|
        { content: name, count: count }
      end

      words = messages
        .map { |m| m[:content].downcase }
        .map { |c| c.split(' ') }.flatten
        .group_by { |n| n }.values
        .sort { |a, b| b.length <=> a.length }
        .map { |a| { content: a[0], count: a.length } }

      json({
        messages: messages,
        users: users,
        words: words
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
  end
end
