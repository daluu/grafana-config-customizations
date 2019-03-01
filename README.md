# Grafana configuration customization for deployments

A proof of concept sample to address: https://community.grafana.com/t/best-way-to-automatically-provision-notification-channel/7979/3.

Might cover more customizations in the future.

To build image:

`docker build -t your_image_name [--build-arg AWS_ACCESS_KEY_ID --build-arg AWS_SECRET_ACCESS_KEY] .`

The build args to pass in environment variables are optional if you don't want to hard code in values in the config/installer file. I don't know if that really works, just a sample on how you might pass in the env vars.

To verify config:

`docker run --rm -it -p 3000:3000 grafana your_image_name`

then open http://localhost:3000, and login with the default (admin,admin). Browse the UI and verify the alert notification channels created during build/deployment. Not sure if you can verify the SMTP email configuration and external image storage configuration in UI. If not, can do so from the shell, something like:

`docker run --rm -it -p 3000:3000 your_image_name bash`

and then navigate to `/opt/grafana/conf/defaults.ini` to view the customized configuration. To start up grafana dashboard from bash shell run `/opt/grafana/bin/grafana-server -homepath /opt/grafana`. I might have edited the wrong INI file in this demo, but you get the gist of what needs to be done.

To see how the customizations were done see the file in this repo `install/install.sh` along with the matching alert notification channel API request body JSON definitions in same install folder.

The docker-based grafana setup used for demo was taken from:

# docker-graphite-grafana

https://github.com/lukess/docker-graphite-grafana

[![](https://images.microbadger.com/badges/image/lukess/docker-graphite-grafana.svg)](http://microbadger.com/images/lukess/docker-graphite-grafana "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/lukess/docker-graphite-grafana.svg)](http://microbadger.com/images/lukess/docker-graphite-grafana "Get your own version badge on microbadger.com")
