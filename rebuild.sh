#!/bin/sh
set -e

docker stop $(docker ps -aq)
./bin/moodle-docker-compose up -d

rm -rf mount/moodle/adminer
rm -rf mount/moodle/moosh
cp -r docker_dev_env_install/additional_files/moosh mount/moodle/moosh
cp -r docker_dev_env_install/additional_files/adminer mount/moodle/adminer

docker exec -it moodledocker_db_1 psql --username=moodle --dbname=postgres -c "drop database moodle"
docker exec -it moodledocker_db_1 psql --username=moodle --dbname=postgres -c "create database moodle"

./bin/moodle-docker-compose exec phpfpm php admin/cli/install_database.php --agree-license --adminpass=admin --adminemail=admin@localhost.com --shortname=moodle --fullname=moodle --summary=moodle

./bin/moodle-docker-compose exec phpfpm php moosh/moosh.php -n config-set registrationpending 0 core

# ******************** ADD MOODLE USERS *************************

users=( student student1 student2 teacher teacher1)
for i in "${users[@]}"
do
	./bin/moodle-docker-compose exec phpfpm php moosh/moosh.php -n user-create --password $i --email $i@localhost.com --firstname $i --lastname $i $i
done

# ******************** CREATE ADMIN USER FOR PSQL *************************

docker exec -it moodledocker_db_1 psql -U moodle -c "CREATE ROLE admin SUPERUSER CREATEDB CREATEROLE LOGIN;"
docker exec -it moodledocker_db_1 psql -U moodle -c "ALTER USER admin WITH PASSWORD 'admin';"
