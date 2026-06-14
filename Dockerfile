FROM ruby:3.3.6-slim-bookworm

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      postgresql-client \
      libvips-dev \
      libjemalloc2 \
      curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN chmod +x bin/docker-entrypoint-prod.sh

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint-prod.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
