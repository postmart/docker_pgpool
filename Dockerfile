FROM      ubuntu:trusty
MAINTAINER Postmart "postmart@me.com"
RUN apt-get update && apt-get install -y postgresql-9.3 postgresql-server-dev-9.3 \
                                         postgresql-contrib-9.3 openssh-server \
                                         make git g++ libsqlite3-dev nodejs 

ADD keys/install.ruby /tmp/install.ruby
RUN /tmp/install.ruby

