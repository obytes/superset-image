FROM apache/superset
# We switch to root
USER root

ENV TINI_VERSION v0.19.0
RUN curl --show-error --location --output /tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64
RUN chmod +x /tini

RUN 	curl --silent --show-error https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip && \
        curl --silent --show-error --location --output /tmp/amazon-ssm-agent.deb https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb && \
        unzip /tmp/awscliv2.zip && \
        dpkg -i /tmp/amazon-ssm-agent.deb && \
        ./aws/install && \
        rm -rf /tmp/awscliv2.zip && \
        set -ex \
        && apt-get update \
        && apt-get install -qq -y --no-install-recommends \
        sudo \
        make \
        unzip \
        curl \
        jq \
        && rm -rf /var/lib/apt/lists/* \
        && usermod -aG sudo superset \
        && echo "superset ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# We install the Python interface for Redis
COPY local_requirements.txt .
RUN pip install -r local_requirements.txt
# We add the superset_config.py file to the container
COPY superset_config.py /app/
# We tell Superset where to find it
ENV SUPERSET_CONFIG_PATH /app/superset_config.py
COPY /docker/superset-entrypoint.sh /app/docker/
COPY /docker/docker-bootstrap.sh /app/docker/
COPY /docker/docker-init.sh /app/docker
COPY /docker/docker-entrypoint.sh /app/docker/

# We give permissions to different files
RUN chmod +x /app/docker/superset-entrypoint.sh
RUN chmod +x /app/docker/docker-entrypoint.sh
RUN chmod +x /app/docker/docker-init.sh
RUN chmod +x /app/docker/docker-bootstrap.s

# We switch back to the `superset` user
USER superset
ENTRYPOINT ["/tini", "-g", "--","/app/docker/docker-entrypoint.sh"]