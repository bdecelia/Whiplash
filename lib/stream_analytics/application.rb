require 'sinatra/base'

module StreamAnalytics
  class Application < Sinatra::Application
    get '/' do
      'hi'
    end
  end
end
