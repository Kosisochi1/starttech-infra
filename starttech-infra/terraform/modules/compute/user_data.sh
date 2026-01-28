#!/bin/bash
set -eux

#------------------------------
# Variables
#------------------------------
APP_DIR=/opt/starttech
LOG_DIR=/var/log/starttech
ENV_FILE=$APP_DIR/.env


#------------------------------
# Update packages
#------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y unzip curl

#------------------------------
# Install AWS CLI v2
#------------------------------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
aws --version

#------------------------------
# Install CloudWatch Agent
#------------------------------
curl -o /tmp/amazon-cloudwatch-agent.deb \
  https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get -f install -y
systemctl enable amazon-cloudwatch-agent

#------------------------------
# Create app directories and logs
#------------------------------
mkdir -p $APP_DIR $LOG_DIR
touch $LOG_DIR/backend.log $LOG_DIR/backend-error.log
chmod 644 $LOG_DIR/*.log

#------------------------------
# Fetch backend binary
#------------------------------
aws s3 cp s3://starttech-deployments-bucket/server $APP_DIR/backend
chmod +x $APP_DIR/backend

#------------------------------
# Fetch systemd service
#------------------------------
aws s3 cp s3://starttech-deployments-bucket/starttech-backend.service /etc/systemd/system/starttech-backend.service

#------------------------------
# Fetch environment variables from SSM
#------------------------------
ENV_FILE=/opt/starttech/.env
rm -f $ENV_FILE
touch $ENV_FILE

# Fetch parameters and write to .env
apt-get install -y jq

set -a
aws ssm get-parameters-by-path \
  --path "/starttech/backend" \
  --with-decryption \
  --query "Parameters[*]" \
  --output json | jq -r '.[] | "\(.Name | split("/")[-1])=\(.Value)"' > $ENV_FILE
set +a
chown root:root /opt/starttech/.env


chmod 600 $ENV_FILE
#chown root:root /opt/starttech/.env


# Debug: show what was written
echo "===== .env contents ====="
cat $ENV_FILE
echo "========================="

#mkdir -p /opt/starttech /var/log/starttech
chown -R ubuntu:ubuntu  /var/log/starttech
chmod +x /opt/starttech/backend

#------------------------------
# Enable and start backend service
#------------------------------
systemctl daemon-reload
systemctl enable starttech-backend
systemctl restart starttech-backend

#------------------------------
# Configure CloudWatch Agent to watch logs
#------------------------------
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/starttech/backend.log",
            "log_group_name": "/starttech/backend",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/starttech/backend-error.log",
            "log_group_name": "/starttech/backend-error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

#------------------------------
# Start CloudWatch Agent
#------------------------------
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
