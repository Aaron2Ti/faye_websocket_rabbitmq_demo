# Backend - websocket

## Requirements

1. accept the job requests from the clients.
2. forward the jobs to the rabbitmq, there're further job processing workers 
   which would process them.
3. waiting for the processing results, when there's any, stream the results back
   to the client.

## Howto

1. start the server

```
bundle exec thin --rackup config.ru start
```
