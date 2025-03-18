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
        git clone https://github.com/stevethomas15977/afe_chat.git
        git checkout $BRANCH_NAME
        
        sh -c "cat > $HOME/.env" <<EOG
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
        EOG

        # Create a python virtual environment
        python_version=$(python3 --version | awk '{print $2}')
        $HOME/.local/bin/uv venv --python $python_version
        $HOME/.local/bin/uv sync  

        # Adjust permissions
        chown -R ubuntu:ubuntu $HOME

        touch /var/log/user_data_complete
        chmod 644 /var/log/user_data_complete

    EOF
}