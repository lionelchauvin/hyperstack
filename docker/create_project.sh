#!/bin/bash

if [ "$1" = "" ]; then
  echo "gimme a name please"
  exit 0
fi

project_name=$1

echo "create local git $project_name"

mkdir $project_name
cd $project_name
git init

######## run ###############################

cat >run << 'EOL'
#!/bin/bash

if ! which docker-compose > /dev/null; then
  echo "install docker"
  sudo ./install_docker
fi

#max_user_watches=`cat /proc/sys/fs/inotify/max_user_watches`
#if [ "$max_user_watches" -lt "524288" ]; then
#  echo "increase max files inotify can watch"
#  sudo sysctl fs.inotify.max_user_watches=524288
#  sudo sysctl fs.inotify.max_queued_events=999999
#  sudo sysctl -p
#fi

echo "
USER_UID=$(id -u)
USER_GID=$(id -g)
" > .env

docker-compose run app bundle exec $@
EOL

chmod +x run

############ rspec #########################

cat >rspec << 'EOL'
#!/bin/bash
./run rspec $@
EOL

chmod +x rspec

############ clean #########################

cat >clean << 'EOL'
#!/bin/bash
docker-compose down -v --rmi 'all' --remove-orphans
EOL

chmod +x clean

############ docker-compose.yml ############

cat >docker-compose.yml << 'EOL'
version: '3.2'
volumes:
  postgres-data:
  postgres-run:
services:
  db:
    image: postgres
    environment:
      - POSTGRES_USER=docker_postgres
      - POSTGRES_PASSWORD=
      - POSTGRES_DB=postgres
    volumes:
      - type: 'volume'
        source: postgres-run
        target: /var/run/postgresql/
      - type: 'volume'
        source: postgres-data
        target: /var/lib/postgresql/data
  app:
    build:
      context: .
      dockerfile: Dockerfile
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec foreman start"
    user: "${USER_UID}:${USER_GID}"
    tty: true
    environment:
      - TERM=xterm-256color
      - HOME=/app # important for bundler because it tries to check if / is writable
      - BUNDLE_PATH=/app/.bundle
      - BUNDLE_BIN=/app/.bundle/bin
      - GEM_HOME=/app/.bundle
    depends_on:
      - db
    volumes:
      - .:/app
      - type: 'volume'
        source: postgres-run
        target: /var/run/postgresql/
    ports:
      - 5000:5000
      - 25222:25222
EOL

############ dockerfile ####################

cat >dockerfile << 'EOL'
FROM ruby:2.6.0

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Install apt based dependencies required to run Rails as
# well as RubyGems. As the Ruby image itself is based on a
# Debian image, we use apt-get to install those.
RUN apt-get update && apt-get install -y build-essential nodejs yarn libpq-dev postgresql-client sqlite3 libsqlite3-dev --fix-missing --no-install-recommends

# Configure the main working directory. This is the base
# directory used in any further RUN, COPY, and ENTRYPOINT
# commands.
WORKDIR /app

# Copy the main application.
COPY . ./

COPY docker-entrypoint.sh /usr/bin/
RUN chmod u+x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ./docker-entrypoint.sh
EOL

############ docker-entrypoint.sh ##########

cat >docker-entrypoint.sh << 'EOL'
#!/bin/bash

bundle check || bundle install --binstubs="$BUNDLE_BIN"

if [ ! -f 'tmp/db_created' ] && [ -d 'tmp' ]; then
  echo "create database"
  rake db:create
  rake db:migrate
  touch tmp/db_created
fi

exec "$@"
EOL

chmod +x docker-entrypoint.sh

############ install_docker ################

cat >install_docker << 'EOL'
#!/bin/bash

distro_name=`lsb_release -is`

case $distro_name in
"neon")
  supported=true
  distro_name="ubuntu"
  ;;
"ubuntu")
  supported=true
  ;;
"debian")
  supported=true
  ;;
*)
  supported=false
esac

if [ $supported = true ]; then

  apt update

  apt install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      software-properties-common

  curl -fsSL "https://download.docker.com/linux/$distro_name/gpg" | apt-key add -

  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/$distro_name \
    $(lsb_release -cs) \
    stable"

  apt update

  apt install docker-ce

  curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

  chmod +x /usr/local/bin/docker-compose

  sudo chmod a+rwx /var/run/docker.sock # TODO

fi
EOL

chmod +x install_docker

############ Gemfile #######################

cat >Gemfile << 'EOL'
source "https://rubygems.org"
gem 'rails', '5.2.3'
EOL

############ database.yml #################

cat >database.yml << 'EOL'
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see Rails configuration guide
  # http://guides.rubyonrails.org/configuring.html#database-pooling
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: db
  port: 5432
  user: docker_postgres
  password:

development:
  <<: *default
  database: app_development

test:
  <<: *default
  database: app_test

production:
  <<: *default
  database: app_production
  username: app
  password: <%= ENV['APP_DATABASE_PASSWORD'] %>
EOL

##############################################

curl https://raw.githubusercontent.com/hyperstack-org/hyperstack/edge/install/rails-webpacker.rb > rails-webpacker.rb
sed -i '/git :init/d' rails-webpacker.rb
sed -i '/git init/d' rails-webpacker.rb
sed -i '/git add/d' rails-webpacker.rb
sed -i '/git commit/d' rails-webpacker.rb

template="rails-webpacker.rb"
./run rails new . -d postgresql -T --template="$template" --skip-bundle -f

mv database.yml config/database.yml

./run rails webpacker:install

echo "===================================================="

./run echo "finished !!!"

echo "To launch your server, execute:"
echo "cd $project_name"
echo "docker-compose up"
echo "In your browser: http://localhost:5000"

