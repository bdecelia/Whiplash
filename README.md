# youtube-stream-analytics

A small Sinatra application to show relevant analytics/metrics about a
YouTube livestream.


### Development

Run the following commands to boot the application. This assumes you
already have Docker installed on the host computer.

```bash
docker build -t youtube-stream-analytics .
docker run -p 3000:3000 -e YOUTUBE_API_KEY=apikeyhere youtube-stream-analytics
```
