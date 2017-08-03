# youtube-stream-analytics

A small Sinatra application to show relevant analytics/metrics about a
YouTube livestream.

### Development

Run the following commands to boot the application. This assumes you
already have Docker installed on the host computer. Make sure you have
an `.env` file with `YOUTUBE_API_KEY` defined -- see `.env.example` for
an example of how to do this.

```bash
docker build -t youtube-stream-analytics .
docker run -p 3000:3000 youtube-stream-analytics
```
### Accessing the Live-chat Data

Open up ruby console using ` irb ` 
then ` require 'rest-client' `

Go to youtube and find the id of the live data you wish to view the live chat stream from. 
Example: watch?v=pi8bY8ncaRY
The ID is everything after v= 

on the console type 
``` RestClient.post('localhost:3000/video', { id: 'insert-id-from-live-video' }) ```
Copy the "live-chat-id" and paste on your browser the following with your live chat id

``` http://localhost:3000/analytics?live_chat_id=paste-here ```

