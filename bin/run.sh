#!/bin/bash -ex

export PATH=$PATH:/root/.local/bin:.local/bin
export FACTORIO_VERSION=0.16.51

sudo systemctl start docker
sudo docker pull dtandersen/factorio:${FACTORIO_VERSION}

sudo mkdir -p /opt/factorio
sudo chown 845:845 /opt/factorio
sudo aws s3 sync s3://factorio-server /opt/factorio --region eu-central-1 --delete
sudo chown 845:845 /opt/factorio/*

cat <<EOF > /tmp/backupSavesToS3.sh
#!/bin/bash -e
export PATH=$PATH
echo "($(date)) Running backup saves to S3"
sudo aws s3 sync /opt/factorio s3://factorio-server --region eu-central-1
sudo chown 845:845 /opt/factorio/*
echo
EOF

cat <<EOF > /tmp/backupOnShutdown.service
[Unit]
Description=Backup save on shutdown
Requires=network.target networking.service network-online.target nss-lookup.target systemd-resolved
DefaultDependencies=no
Before=shutdown.target reboot.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/true
ExecStop=/tmp/backupSavesToS3.sh

[Install]
WantedBy=multi-user.target
EOF

sudo chmod +x /tmp/backupSavesToS3.sh
# backup every 2 minutes
sudo echo "*/2 * * * * /tmp/backupSavesToS3.sh >> /tmp/backupSavesToS3.log 2>&1" > /tmp/backupSavesToS3.cron
sudo chmod 0644 /tmp/backupSavesToS3.cron
sudo crontab /tmp/backupSavesToS3.cron
sudo crontab -l
sudo systemctl restart crond.service

sudo ln -s /tmp/backupOnShutdown.service /etc/systemd/system/backupOnShutdown.service
sudo systemctl daemon-reload

sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio:Z \
  --name factorio \
  --restart=always  \
  dtandersen/factorio:${FACTORIO_VERSION}
