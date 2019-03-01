

# requirements
sed -i "s/archive.ubuntu.com/us.archive.ubuntu.com/g" /etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends wget bzip2 vim git ca-certificates python python-dev python-django-tagging nginx uwsgi uwsgi-plugin-python python-twisted-core python-cairo-dev crudini curl

# dumb-init
wget --no-check-certificate https://github.com/Yelp/dumb-init/releases/download/v1.0.1/dumb-init_1.0.1_amd64.deb
dpkg -i dumb-init_1.0.1_amd64.deb && rm dumb-init_1.0.1_amd64.deb

# Grafana
cd /opt
GRAFANA=grafana-4.0.2-1481203731
wget --no-check-certificate https://grafanarel.s3.amazonaws.com/builds/${GRAFANA}.linux-x64.tar.gz
tar zxvf ${GRAFANA}.linux-x64.tar.gz
rm ${GRAFANA}.linux-x64.tar.gz
ln -s ${GRAFANA} grafana

# customizations for alarm notification, add/remove/edit fields you need to set/override from defaults
# email alert config
crudini --set --existing /opt/grafana/conf/defaults.ini smtp enabled true
crudini --set --existing /opt/grafana/conf/defaults.ini smtp from_address admin@mine.com
crudini --set --existing /opt/grafana/conf/defaults.ini smtp host mail.mine.com:25
#crudini --set --existing /opt/grafana/conf/defaults.ini smtp user ${MAIL_USER}
#crudini --set --existing /opt/grafana/conf/defaults.ini smtp password ${MAIL_PASSWD}
#crudini --set --existing /opt/grafana/conf/defaults.ini smtp cert_file pathTo/file
#crudini --set --existing /opt/grafana/conf/defaults.ini smtp key_file pathTo/file
#crudini --set --existing /opt/grafana/conf/defaults.ini smtp skip_verify true

# external image storage config
crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage provider s3
crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage.s3 bucket_url s3://my-bucket/my-folder
crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage.s3 access_key ${AWS_ACCESS_KEY_ID}
crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage.s3 secret_key ${AWS_SECRET_ACCESS_KEY}
#crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage provider webdav
#crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage.webdav url http://my.site.com
#crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage.webdav username ${WEBDAV_USER}
#crudini --set --existing /opt/grafana/conf/defaults.ini external_image_storage.webdav password ${WEBDAV_PASSWD}

# grafana server config
crudini --set --existing /opt/grafana/conf/defaults.ini server domain www.mine.com
#crudini --set --existing /opt/grafana/conf/defaults.ini server http_port 8081
#crudini --set --existing /opt/grafana/conf/defaults.ini server http_addr 192.168.1.2

# start up grafana & set alert notification channels via API
/opt/grafana/bin/grafana-server -homepath /opt/grafana </dev/null &>/dev/null &
# give a little server startup time before doing configuration, just in case
sleep 5
cd /root
curl -d "@email_alert_notifier.json" -H "Content-Type: application/json" -X POST http://admin:admin@localhost:3000/api/alert-notifications
curl -d "@slack_alert_notifier.json" -H "Content-Type: application/json" -X POST http://admin:admin@localhost:3000/api/alert-notifications
# ^^ for authentication, kept things simple and used default basic auth instead of creating org/user + API token for this
# http://docs.grafana.org/tutorials/api_org_token_howto/
# for more details on the alert setup API
# http://docs.grafana.org/http_api/alerting/
# http://docs.grafana.org/alerting/notifications/#all-supported-notifier
# NOTE: no need to stop the grafana server, it will be terminated at end of (docker) build while persisting the API changes to file in the docker image

# Graphite
cd /root
wget https://pypi.python.org/packages/ad/30/5ab2298c902ac92fdf649cc07d1b7d491a241c5cac8be84dd84464db7d8b/pytz-2016.4.tar.gz#md5=a3316cf3842ed0375ba5931914239d97
tar -zxvf pytz-2016.4.tar.gz
rm pytz-2016.4.tar.gz
cd /root/pytz-2016.4
python setup.py install

cd /root
git clone https://github.com/graphite-project/whisper.git /root/whisper
cd /root/whisper
git checkout ${GRAPHITE_VERSION}
python setup.py install

git clone https://github.com/graphite-project/carbon.git /root/carbon
cd /root/carbon
git checkout ${GRAPHITE_VERSION}
python setup.py install

git clone https://github.com/graphite-project/graphite-web.git /root/graphite-web
cd /root/graphite-web
git checkout ${GRAPHITE_VERSION}
python setup.py install

cd /opt/graphite/webapp/graphite
python manage.py syncdb --noinput
cp /opt/graphite/conf/carbon.conf.example /opt/graphite/conf/carbon.conf
cp /opt/graphite/conf/storage-schemas.conf.example /opt/graphite/conf/storage-schemas.conf
