require 'sinatra/base'
require 'rest-client'

module StreamAnalytics
  class Application < Sinatra::Application
    get '/' do
      erb :index
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
      messages = youtube_api('liveChat/messages', { liveChatId: params[:live_chat_id], part: 'id, snippet, authorDetails' })

      messages = messages['items'].map do |message|
        {
          author: message['authorDetails']['displayName'],
          content: message['snippet']['textMessageDetails']['messageText'],
          timestamp: message['snippet']['publishedAt']
        }
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
