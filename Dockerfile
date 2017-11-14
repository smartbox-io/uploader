FROM ruby:2
ENV BUILD_PACKAGES="build-essential"
RUN apt-get update -qq && apt-get install -y $BUILD_PACKAGES libmysqlclient-dev && rm -rf /var/lib/apt/lists/*
RUN mkdir /uploader
WORKDIR /uploader
ADD Gemfile /uploader/Gemfile
ADD Gemfile.lock /uploader/Gemfile.lock
RUN bundle install
RUN apt-get remove --purge -y $BUILD_PACKAGES && apt-get autoremove --purge -y && apt-get -y clean
ENV PATH "/uploader/bin:${PATH}"
ADD . /uploader
