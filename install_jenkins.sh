#  run this then in the ec2 terminal run whats inside jenkins.yaml

#!/bin/bash
# Stop and remove any existing Jenkins containers
docker stop jenkins || true

# Define Jenkins image
JENKINS_IMAGE="custom-jenkins"

# Create a Dockerfile for Jenkins with pre-installed plugins
cat <<EOF > Dockerfile
FROM jenkins/jenkins:lts

# Install necessary plugins with latest versions
RUN jenkins-plugin-cli --plugins \
    ssh-agent:latest \
    ec2:latest \
    workflow-aggregator:latest \
    git:latest \
    github:latest \
    github-branch-source:latest \
    job-dsl:latest \
    configuration-as-code:latest \
    pipeline-stage-view:latest \
    blueocean:latest \
    docker-plugin:latest \
    docker-workflow:latest  # Docker Pipeline plugin

# Install AWS CLI and Docker inside Jenkins container
USER root
RUN apt-get update && apt-get install -y awscli docker.io
USER jenkins
EOF


# Build the Jenkins image
docker build -t $JENKINS_IMAGE .

# Create required directories
sudo mkdir -p /var/jenkins_home/casc_configs
sudo chown -R $USER:$USER /var/jenkins_home

# Create minimal configuration
cat <<EOF > /var/jenkins_home/casc_configs/jenkins.yaml
jenkins:
  systemMessage: "Jenkins configured with minimal configuration"
EOF

# Run Jenkins container
docker run -d --name jenkins \
  --restart=unless-stopped \
  -p 8080:8080 -p 50000:50000 \
  -v /var/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs \
  $JENKINS_IMAGE


