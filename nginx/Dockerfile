FROM ubuntu:24.04

# Install required packages
RUN apt update && apt install -y nginx curl wget gnupg

# Add MongoDB GPG key and repository for mongosh
RUN wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add - && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Install MongoDB shell (mongosh)
RUN apt update && apt install -y mongodb-mongosh

# Set working directory
WORKDIR /var/www/html

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port 80
EXPOSE 80

# Use the entrypoint script
CMD ["/entrypoint.sh"]