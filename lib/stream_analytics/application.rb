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
        stream_id: video['liveStreamingDetails']['activeLiveChatId'],
        stream_name: video['snippet']['title']
      })
    end

    get '/analytics' do
      json({
        messages: [],
        users: [ { count: 100, content: 'Alice' } ],
        words: [ { count: 100, name: 'cool' } ]
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
