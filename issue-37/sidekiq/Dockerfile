FROM ruby:2.6.5-alpine

RUN apk add --no-cache tzdata~=2021 \
 && gem install sidekiq -v "~> 5.0"

ENTRYPOINT [ "sidekiq" ]
CMD [ "-r", "/sidekiq.rb", "-C", "/sidekiq.yml" ]
