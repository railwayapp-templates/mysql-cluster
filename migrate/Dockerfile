FROM ubuntu:20.04

# Install necessary tools
RUN apt-get update && apt-get install -y \
    mysql-client \
    gzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install MinIO client
RUN curl -O https://dl.min.io/client/mc/release/linux-amd64/mc \
    && chmod +x mc \
    && mv mc /usr/local/bin/

# Copy the script into the container
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Run the script when the container starts
ENTRYPOINT ["/run.sh"]
