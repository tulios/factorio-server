#!/bin/bash -ex

export PATH=$PATH:.local/bin

sudo systemctl start docker
sudo docker pull dtandersen/factorio:stable

sudo mkdir -p /opt/factorio
aws s3 sync s3://factorio-server /opt/factorio --region eu-central-1 --delete

cat <<EOF > /tmp/backupSavesToS3.sh
#!/bin/bash -e
export PATH=$PATH
echo "($(date)) Running backup saves to S3"
aws s3 sync /opt/factorio s3://factorio-server --region eu-central-1
echo
EOF

sudo chmod +x /tmp/backupSavesToS3.sh
# backup every 2 minutes
sudo echo "*/2 * * * * /tmp/backupSavesToS3.sh >> /tmp/backupSavesToS3.log 2>&1" > /tmp/backupSavesToS3.cron
sudo chmod 0644 /tmp/backupSavesToS3.cron
sudo crontab /tmp/backupSavesToS3.cron
sudo crontab -l
sudo systemctl restart crond.service

sudo docker run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /opt/factorio:/factorio \
  --name factorio \
  --restart=always  \
  dtandersen/factorio:stable
