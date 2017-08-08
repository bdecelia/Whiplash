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
      stopwords = [".","?","!","-","a","a's","able","about","above","according","accordingly","across","actually","after","afterwards","again","against","ain't","all","allow","allows","almost","alone","along","already","also","although","always","am","among","amongst","an","and","another","any","anybody","anyhow","anyone","anything","anyway","anyways","anywhere","apart","appear","appreciate","appropriate","are","aren't","around","as","aside","ask","asking","associated","at","available","away","awfully","b","be","became","because","become","becomes","becoming","been","before","beforehand","behind","being","believe","below","beside","besides","best","better","between","beyond","both","brief","but","by","c","c'mon","c's","came","can","can't","cannot","cant","cause","causes","certain","certainly","changes","clearly","co","com","come","comes","concerning","consequently","consider","considering","contain","containing","contains","corresponding","could","couldn't","course","currently","d","definitely","described","despite","did","didn't","different","do","does","doesn't","doing","don't","done","down","downwards","during","e","each","edu","eg","eight","either","else","elsewhere","enough","entirely","especially","et","etc","even","ever","every","everybody","everyone","everything","everywhere","ex","exactly","example","except","f","far","few","fifth","first","five","followed","following","follows","for","former","formerly","forth","four","from","further","furthermore","g","get","gets","getting","given","gives","go","goes","going","gone","got","gotten","greetings","h","had","hadn't","happens","hardly","has","hasn't","have","haven't","having","he","he's","hello","help","hence","her","here","here's","hereafter","hereby","herein","hereupon","hers","herself","hi","him","himself","his","hither","hopefully","how","howbeit","however","i","i'd","i'll","i'm","i've","ie","if","ignored","immediate","in","inasmuch","inc","indeed","indicate","indicated","indicates","inner","insofar","instead","into","inward","is","isn't","it","it'd","it'll","it's","its","itself","j","just","k","keep","keeps","kept","know","known","knows","l","last","lately","later","latter","latterly","least","less","lest","let","let's","like","liked","likely","little","look","looking","looks","ltd","m","mainly","many","may","maybe","me","mean","meanwhile","merely","might","more","moreover","most","mostly","much","must","my","myself","n","name","namely","nd","near","nearly","necessary","need","needs","neither","never","nevertheless","new","next","nine","no","nobody","non","none","noone","nor","normally","not","nothing","novel","now","nowhere","o","obviously","of","off","often","oh","ok","okay","old","on","once","one","ones","only","onto","or","other","others","otherwise","ought","our","ours","ourselves","out","outside","over","overall","own","p","particular","particularly","per","perhaps","placed","please","plus","possible","presumably","probably","provides","q","que","quite","qv","r","rather","rd","re","really","reasonably","regarding","regardless","regards","relatively","respectively","right","s","said","same","saw","say","saying","says","second","secondly","see","seeing","seem","seemed","seeming","seems","seen","self","selves","sensible","sent","serious","seriously","seven","several","shall","she","should","shouldn't","since","six","so","some","somebody","somehow","someone","something","sometime","sometimes","somewhat","somewhere","soon","sorry","specified","specify","specifying","still","sub","such","sup","sure","t","t's","take","taken","tell","tends","th","than","thank","thanks","thanx","that","that's","thats","the","their","theirs","them","themselves","then","thence","there","there's","thereafter","thereby","therefore","therein","theres","thereupon","these","they","they'd","they'll","they're","they've","think","third","this","thorough","thoroughly","those","though","three","through","throughout","thru","thus","to","together","too","took","toward","towards","tried","tries","truly","try","trying","twice","two","u","un","under","unfortunately","unless","unlikely","until","unto","up","upon","us","use","used","useful","uses","using","usually","uucp","v","value","various","very","via","viz","vs","w","want","wants","was","wasn't","way","we","we'd","we'll","we're","we've","welcome","well","went","were","weren't","what","what's","whatever","when","whence","whenever","where","where's","whereafter","whereas","whereby","wherein","whereupon","wherever","whether","which","while","whither","who","who's","whoever","whole","whom","whose","why","will","willing","wish","with","within","without","won't","wonder","would","wouldn't","x","y","yes","yet","you","you'd","you'll","you're","you've","your","yours","yourself","yourselves","z","zero"]
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
  end
end
