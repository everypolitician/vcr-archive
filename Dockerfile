FROM ruby:2.2.3

RUN touch ~/.gemrc
RUN echo 'gem: --no-ri --no-rdoc' >> ~/.gemrc
RUN gem install rubygems-update
RUN update_rubygems
RUN gem install bundler

WORKDIR /vcr-archive/

RUN mkdir -p /tmp/

COPY . /vcr-archive/

RUN bundle install --path vendor/bundle
