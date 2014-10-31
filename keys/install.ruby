cd /tmp
wget http://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.2.tar.gz
tar -xzvf ruby-2.1.2.tar.gz
cd ruby-2.1.2/
./configure && make && make install

gem install bundle therubyracer 

