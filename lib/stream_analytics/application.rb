require 'sinatra/base'

module StreamAnalytics
  class Application < Sinatra::Application
    get '/' do
      'hi'
    end

    post '/video' do
      json({
        channel_name: '',
        stream_id: '',
        stream_name: ''
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

    def json(data)
      content_type 'application/json'
      JSON.dump(data)
    end
  end
end
