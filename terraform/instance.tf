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
        export BRANCH_NAME="${var.branch}"
        export GH_PAT="${var.ghpat}"
        export APP_SECRET="${var.appsecret}"
        export ENV="${var.env}"
        export APP="afe_chat"
        export APP_ROOT="/home/ubuntu"
        export APP_PATH=$APP_ROOT/$APP
        
        # Clone the GitHub repository
        cd $APP_ROOT
        mkdir -p $APP_PATH
        cd $APP_PATH
        git clone https://github.com/stevethomas15977/afe_chat.git .
        git checkout $BRANCH_NAME

        # Adjust permissions
        chown -R ubuntu:ubuntu $APP_PATH

        sh -c "cat > $APP_PATH/.env" <<EOG
        PYTHONPATH="$PYTHONPATH:models:helpers:services:database"
        VERSION="1.0"
        ENV="$ENV"
        APP="$APP"
        APP_ROOT="$APP_ROOT"
        APP_PATH="$APP_PATH"
        USERNAME="afe_chat"
        APP_SECRET="$APP_SECRET"
        S3_BUCKET_NAME="$S3_BUCKET_NAME"
        LANGCHAIN_API_KEY="$LANGCHAIN_API_KEY"
        LANGCHAIN_TRACING_V2="true"
        OPENAI_API_KEY="$OPENAI_API_KEY"
        SERP_API_KEY="$SERP_API_KEY"
        EOG

        touch /var/log/user_data_complete
        chmod 644 /var/log/user_data_complete

    EOF
}