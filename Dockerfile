FROM jenkins/jenkins:2.541.2-jdk21
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    lsb-release ca-certificates curl unzip wget python3 python3-pip python3-venv jq awscli iputils-ping && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y --no-install-recommends docker-ce-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip

RUN curl -sLo /usr/local/bin/tfsec https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64 && \
    chmod +x /usr/local/bin/tfsec

RUN pip3 install checkov --break-system-packages || echo "Checkov install failed - ignoring for now"

USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow json-path-api"