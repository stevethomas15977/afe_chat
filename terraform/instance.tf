# Create an access key for the Lightsail bucket
resource "aws_lightsail_bucket_access_key" "offset-well-identification-lightsail-bucket-access-key" {
  bucket_name = var.s3_bucket
}

# Create a new Lightsail Key Pair
resource "aws_lightsail_key_pair" "key-pair" {
  name = "${var.app}-key-pair"
}

# Lightsail Instance
resource "aws_lightsail_instance" "instance" {
  name                  = "${var.app}-instance"
    availability_zone   = "us-east-1a"
    blueprint_id        = "ubuntu_24_04"
    bundle_id           = "medium_3_0" 
    key_pair_name       = aws_lightsail_key_pair.key-pair.name
    user_data = <<-EOF
        #!/bin/bash
        apt-get update -y

        TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
        export PRIVATE_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4`

        # Set up the environment variables
        export HOME="/home/ubuntu"
        export BRANCH_NAME="${var.branch}"
        export GH_PAT="${var.ghpat}"
        export APP_SECRET="${var.appsecret}"
        export ENV="${var.env}"
        export APP="afe_chat"
        export LANGCHAIN_API_KEY="${var.langchain_api_key}"
        export OPENAI_API_KEY="${var.openai_api_key}"
        export SERPAPI_API_KEY="${var.serpapi_api_key}"
        
        # Install UV
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source $HOME/.local/bin/env

        # Clone the GitHub repository
        cd $HOME
        mkdir -p $APP
        cd $APP
        git clone https://github.com/stevethomas15977/afe_chat.git .
        git checkout $BRANCH_NAME
        
        sh -c "cat > $HOME/$APP/.env" <<EOG
        HOME="$HOME"
        PYTHONPATH="$PYTHONPATH:models:helpers:services:database"
        VERSION="1.0"
        ENV="$ENV"
        APP="$APP"
        USERNAME="afe_chat"
        APP_SECRET="$APP_SECRET"
        LANGCHAIN_API_KEY="$LANGCHAIN_API_KEY"
        LANGCHAIN_TRACING_V2="true"
        OPENAI_API_KEY="$OPENAI_API_KEY"
        SERPAPI_API_KEY="$SERPAPI_API_KEY"
        PRIVATE_IP="$PRIVATE_IP"
        EOG

        # Create a python virtual environment
        python_version=$(python3 --version | awk '{print $2}')
        $HOME/.local/bin/uv venv --python $python_version
        $HOME/.local/bin/uv sync  

        # Install NODE and NPM
        sudo apt install nodejs npm -y
        cd $HOME/$APP/app
        npm install
        cd $HOME/$APP/app/src/components
        awk -v env_var="$PRIVATE_IP" '{gsub(/localhost/, env_var, $0); print}' TextArea.tsx > temp_file && mv temp_file TextArea.tsx

        # Setup CORS
        cd $HOME/$APP/api
        awk -v env_var="$PRIVATE_IP" '{gsub(/localhost/, env_var, $0); print}' main.py > temp_file && mv temp_file main.py

        cd $HOME/$APP
        
        # Adjust permissions
        chown -R ubuntu:ubuntu $HOME

        # Create the AFE API service file and start the service
        sudo sh -c "cat > /etc/systemd/system/afe_api.service" <<EOT
        [Unit]
        Description=afe daemon
        After=network.target

        [Service]
        User=ubuntu
        Group=ubuntu
        WorkingDirectory=/home/ubuntu/afe_chat
        ExecStart=/bin/bash /home/ubuntu/afe_chat/start_api.sh

        [Install]
        WantedBy=multi-user.target
        EOT

        sudo setcap 'cap_net_bind_service=+ep' /usr/bin/python3.12

        sudo systemctl daemon-reload
        sudo systemctl start afe_api
        sudo systemctl enable afe_api
        sudo systemctl status afe_api --no-pager

        # Create the AFE APP service file and start the service
        sudo sh -c "cat > /etc/systemd/system/afe_app.service" <<EOT
        [Unit]
        Description=afe daemon
        After=network.target

        [Service]
        User=ubuntu
        Group=ubuntu
        WorkingDirectory=/home/ubuntu/afe_chat
        ExecStart=/bin/bash /home/ubuntu/afe_chat/start_app.sh

        [Install]
        WantedBy=multi-user.target
        EOT

        sudo setcap 'cap_net_bind_service=+ep' /usr/bin/python3.12

        sudo systemctl daemon-reload
        sudo systemctl start afe_app
        sudo systemctl enable afe_app
        sudo systemctl status afe_app --no-pager

        touch /var/log/user_data_complete
        chmod 644 /var/log/user_data_complete

    EOF
}

resource "aws_lightsail_instance_public_ports" "public_ports" {
    instance_name = aws_lightsail_instance.instance.name

    port_info {
      from_port = 3000
      to_port = 3000
      protocol = "tcp"
    }

    port_info {
      from_port = 8000
      to_port = 8000
      protocol = "tcp"
    }
}