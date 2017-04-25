#!/bin/bash

set -e

if [ "$1" = 'ofn' ]; then

  # starting services
  #service postgresql start
  #service elasticsearch start

  # wait for postgres processe coming up
  #until su - postgres -c 'psql -c "select version()"' &> /dev/null; do
  #until
  #  echo "waiting for postgres to be ready..."
  #  sleep 2
  #done


  #until $(mysql -s -N -e -u${OFN_DB_USER} -p${OFN_DB_PASS} -h ${OFN_DB_HOST} "SELECT schema_name FROM information_schema.schemata WHERE SCHEMA_NAME = '${OFN_DB}'"); do
  #  echo "=> Waiting for MariaDB to be ready..."
  #done
  #export tableExists=$(mysql -s -N -e -u${OFN_DB_USER} -p${OFN_DB_PASS} -h ${OFN_DB_HOST} "SELECT * FROM information_schema.tables WHERE table_schema = '${OFN_DB}' AND table_name = 'users'")
  # if [[ -z "${tableExists}" ]]; then
    export rakeSecret=$(rake secret)
    echo "===> Configuring Openfoodnetwork for production please wait..."
    sed -e "s#production:#${RAILS_ENV}:#" -e "s#.*adapter:.*#  adapter: postgresql#" -e "s#.*username:.*#  username: ${OFN_DB_USER}#" -e "s#.*password:.*#  password: ${OFN_DB_PASS}#" -e "s#.*database:.*#  database: ${OFN_DB}\n  host: ${OFN_DB_HOST}#" < ${OFN_DIR}/config/database.yml.pkgr > ${OFN_DIR}/config/database.yml
    cd ${OFN_DIR}
    # populate database
    echo "===> Running db:drop..."
    bundle exec rake db:drop
    echo "===> Running db:create..."
    bundle exec rake db:create
    echo "===> Running db:schema:load..."
    bundle exec rake db:schema:load
    echo "===> Running db:migrate..."
    bundle exec rake db:migrate
    echo "===> Running db:seed..."
    bundle exec rake db:seed
    echo "===> Running openfoodnetwork:dev:load_sample_data..."
    bundle exec rake openfoodnetwork:dev:load_sample_data


    # assets precompile
    echo "===> Running assets:precompile..."
    bundle exec rake assets:precompile

    # delete assets precompile cache
    rm -r tmp/cache
    
  # fi

  echo "===> Starting openfoodnetwork...."
  #su -c "bundle exec script/websocket-server.rb -b 0.0.0.0 start &>> ${OFN_DIR}/log/zammad.log &" zammad
 # su -c "bundle exec script/scheduler.rb start &>> ${OFN_DIR}/log/zammad.log &" zammad

  if [ "${RAILS_SERVER}" == "puma" ]; then
    su -c "bundle exec puma -b tcp://0.0.0.0:3000 -e ${RAILS_ENV} &>> ${OFN_DIR}/log/ofn.log &" zammad
  elif [ "${RAILS_SERVER}" == "unicorn" ]; then
    su -c "bundle exec unicorn -p 3000 -c config/unicorn.rb -E ${RAILS_ENV} &>> ${OFN_DIR}/log/ofn.log &" zammad
  fi

  # wait for zammad processe coming up
  until (echo > /dev/tcp/localhost/3000) &> /dev/null; do
    echo "==> waiting for openfoodnetwork to be ready..."
    sleep 2
  done

  # show url
  echo -e "==> \Openfoodnetwork is ready! Visit the url in your browser to configure!"

  # run shell
  tail -f ${OFN_DIR}/log/ofn.log
  /bin/bash

fi
