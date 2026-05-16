# Custom Jenkins image — includes Docker CLI and Git
FROM jenkins/jenkins:lts

USER root

# Install Docker CLI and Git inside the Jenkins container
RUN apt-get update && \
    apt-get install -y docker.io git && \
    rm -rf /var/lib/apt/lists/*

# Allow the jenkins user to run Docker commands
RUN usermod -aG docker jenkins

USER jenkins
