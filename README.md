# Milestone 1: Load Balanced Web Application with MongoDB

This project demonstrates a load-balanced web application using Docker Compose with multiple NGINX containers, a reverse proxy, and MongoDB for dynamic content.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup](#step-by-step-setup)
- [File Structure](#file-structure)
- [How It Works](#how-it-works)
- [Testing Load Balancing](#testing-load-balancing)
- [Troubleshooting](#troubleshooting)

## Overview

The application consists of:
- **3 NGINX web containers** (horizontally scaled)
- **1 Reverse proxy** (load balancer)
- **1 MongoDB container** (database)
- **Dynamic content** that updates from the database

When you refresh the page, you'll see different container hostnames, proving the load balancer is distributing requests across multiple containers.

## Prerequisites

- Docker Desktop installed and running
- Basic understanding of Docker concepts
- Terminal/Command Prompt access

## Step-by-Step Setup

### Step 1: Create Project Directory

```bash
mkdir Milestone1
cd Milestone1
```

**Explanation:**
- `mkdir Milestone1` - Creates a new directory named "Milestone1"
- `cd Milestone1` - Changes into the newly created directory

### Step 2: Create Docker Compose File

Create `docker-compose.yaml` in the root directory:

```yaml
version: "3.9"

services:
  # Reverse Proxy (Load Balancer)
  reverse-proxy:
    build: ./reverse-proxy
    container_name: milestone1-reverse-proxy
    ports:
      - "8085:80"  # Public entrypoint - same as before
    depends_on:
      - web
    networks:
      - milestone-net

  # Multiple NGINX Web Containers (Horizontally Scaled)
  web:
    build: ./nginx
    # Remove container_name - Docker Compose will auto-generate unique names for replicas
    depends_on:
      - mongo
    networks:
      - milestone-net
    deploy:
      replicas: 3  # Scale to 3 instances

  # MongoDB (Single Instance)
  mongo:
    image: mongo
    container_name: milestone1-mongo
    volumes:
      - mongo-data:/data/db
      - ./mongo-init/init.js:/docker-entrypoint-initdb.d/init.js:ro
    networks:
      - milestone-net

volumes:
  mongo-data:

networks:
  milestone-net:
```

**Explanation of docker-compose.yaml:**

**Version:**
- `version: "3.9"` - Specifies the Docker Compose file format version

**Services:**

1. **reverse-proxy service:**
   - `build: ./reverse-proxy` - Builds from the reverse-proxy directory
   - `container_name: milestone1-reverse-proxy` - Gives the container a specific name
   - `ports: - "8085:80"` - Maps host port 8085 to container port 80
   - `depends_on: - web` - Ensures web service starts before reverse-proxy
   - `networks: - milestone-net` - Connects to custom network

2. **web service:**
   - `build: ./nginx` - Builds from the nginx directory
   - No `container_name` - Docker Compose auto-generates names for replicas
   - `depends_on: - mongo` - Ensures MongoDB starts first
   - `deploy: replicas: 3` - Creates 3 instances of this service

3. **mongo service:**
   - `image: mongo` - Uses official MongoDB image
   - `volumes:` - Mounts data directory and initialization script
   - `./mongo-init/init.js:/docker-entrypoint-initdb.d/init.js:ro` - Mounts init script as read-only

**Networks and Volumes:**
- `milestone-net` - Custom network for service communication
- `mongo-data` - Persistent volume for MongoDB data

### Step 3: Create Directory Structure

```bash
mkdir reverse-proxy
mkdir nginx
mkdir mongo-init
```

**Explanation:**
- Creates separate directories for each service component
- This keeps the project organized and follows Docker best practices

### Step 4: Create Reverse Proxy Configuration

Create `reverse-proxy/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream web_backend {
        server web:80;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://web_backend;
            
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            proxy_cache_bypass 1;
            proxy_no_cache 1;
            
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
            
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }
    }
}
```

**Explanation of nginx.conf:**

**Events block:**
- `worker_connections 1024` - Maximum number of connections per worker process

**HTTP block:**
- `upstream web_backend` - Defines a group of backend servers
- `server web:80` - Points to the web service on port 80

**Server block:**
- `listen 80` - Listens on port 80
- `server_name localhost` - Responds to localhost requests

**Location block:**
- `proxy_pass http://web_backend` - Forwards requests to backend servers
- `proxy_set_header` directives - Pass original request information to backend
- `proxy_cache_bypass 1` and `proxy_no_cache 1` - Disable caching
- `add_header` directives - Add cache-busting headers to responses
- `proxy_connect_timeout` - Connection timeout settings

### Step 5: Create Reverse Proxy Dockerfile

Create `reverse-proxy/Dockerfile`:

```dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
```

**Explanation:**
- `FROM nginx:alpine` - Uses lightweight Alpine Linux NGINX image
- `COPY nginx.conf /etc/nginx/nginx.conf` - Copies our custom configuration

### Step 6: Create MongoDB Initialization Script

Create `mongo-init/init.js`:

```javascript
db = db.getSiblingDB('milestoneDB');

db.students.insertOne({
    name: "Lukas Mues",
    studentId: "12345",
    course: "Linux Webservices"
});

print("Database initialized with student data");
```

**Explanation:**
- `db.getSiblingDB('milestoneDB')` - Creates/accesses the milestoneDB database
- `db.students.insertOne()` - Inserts a student document
- The document contains name, studentId, and course fields
- `print()` - Outputs a message when initialization completes

### Step 7: Create NGINX Web Container Files

Create `nginx/Dockerfile`:

```dockerfile
FROM nginx:alpine

# Install MongoDB client tools
RUN apk add --no-cache mongodb-tools

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy initial HTML file
COPY index.html /var/www/html/index.html

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
```

**Explanation:**
- `FROM nginx:alpine` - Uses Alpine Linux NGINX image
- `RUN apk add --no-cache mongodb-tools` - Installs MongoDB client tools
- `COPY entrypoint.sh /entrypoint.sh` - Copies our startup script
- `RUN chmod +x /entrypoint.sh` - Makes the script executable
- `COPY index.html /var/www/html/index.html` - Copies initial HTML file
- `ENTRYPOINT ["/entrypoint.sh"]` - Sets the container's entrypoint

### Step 8: Create Initial HTML File

Create `nginx/index.html`:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Milestone 1</title>
  </head>
  <body>
    <h1>Loading...</h1>
    <p>This page will be dynamically generated by the entrypoint script.</p>
  </body>
</html>
```

**Explanation:**
- This is a placeholder HTML file
- It will be overwritten by the entrypoint script with dynamic content
- Shows "Loading..." until the container fully starts

### Step 9: Create Entrypoint Script

Create `nginx/entrypoint.sh`:

```bash
#!/bin/bash

# Wait for MongoDB to be ready
until mongosh --host mongo --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    sleep 2
done

# Function to get current name from MongoDB
get_current_name() {
    NAME=$(mongosh --quiet --host mongo --eval 'db = db.getSiblingDB("milestoneDB"); db.students.findOne().name')
    if [ -z "$NAME" ] || [ "$NAME" = "null" ]; then
        NAME="Lukas Mues"
    fi
    echo "$NAME"
}

# Get initial student name from MongoDB
INITIAL_NAME=$(get_current_name)

# Get container info
HOSTNAME=$(hostname)
CONTAINER_ID=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Create a background process to update the name file every 5 seconds
update_name_background() {
    while true; do
        CURRENT_NAME=$(get_current_name)
        echo "$CURRENT_NAME" > /var/www/html/current_name.txt
        sleep 5
    done
}

# Start the background process
update_name_background &

# Create the HTML file
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Milestone 1 - Load Balanced</title>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <style>
      body {
        font-family: Arial, sans-serif;
        text-align: center;
        margin-top: 50px;
      }
      h1 {
        color: #333;
      }
      .hostname {
        margin-top: 20px;
        padding: 10px;
        background-color: #f5f5f5;
        border-radius: 5px;
      }
      .timestamp {
        color: #666;
        font-size: 0.8em;
        margin-top: 10px;
      }
    </style>
    <script>
      async function fetchCurrentName() {
        try {
          const timestamp = new Date().getTime();
          const response = await fetch('/current_name.txt?t=' + timestamp);
          const name = await response.text();
          if (name && name.trim()) {
            document.getElementById('student-name').textContent = name.trim();
          }
        } catch (error) {
          console.log('Could not fetch updated name, using initial name');
        }
      }
      
      window.onload = function() {
        fetchCurrentName();
        setInterval(fetchCurrentName, 3000);
      };
    </script>
  </head>
  <body>
    <h1><span id="student-name">$INITIAL_NAME</span> has reached Milestone 1!!</h1>
    
    <div class="hostname">
      <strong>Container Hostname:</strong> $HOSTNAME<br>
      <strong>Container ID:</strong> $CONTAINER_ID
    </div>
    
    <div class="timestamp">
      Generated at: $TIMESTAMP
    </div>
  </body>
</html>
EOF

# Create initial name file
echo "$INITIAL_NAME" > /var/www/html/current_name.txt

# Start nginx
nginx -g 'daemon off;'
```

**Explanation of entrypoint.sh:**

**MongoDB Wait Loop:**
- `until mongosh --host mongo --eval "db.adminCommand('ping')"` - Waits for MongoDB to be ready
- `> /dev/null 2>&1` - Suppresses output
- `sleep 2` - Waits 2 seconds between attempts

**get_current_name Function:**
- `mongosh --quiet --host mongo` - Connects to MongoDB quietly
- `db.getSiblingDB("milestoneDB")` - Accesses the database
- `db.students.findOne().name` - Gets the student's name
- Fallback to "Lukas Mues" if no name found

**Container Info:**
- `HOSTNAME=$(hostname)` - Gets container hostname
- `CONTAINER_ID=$(hostname)` - Uses hostname as container ID
- `TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')` - Gets current timestamp

**Background Process:**
- `update_name_background()` - Function that updates name file every 5 seconds
- `&` - Runs the process in background
- This ensures the name stays updated if database changes

**HTML Generation:**
- Uses heredoc (`<< EOF`) to create dynamic HTML
- Includes cache-busting meta tags
- JavaScript fetches updated name every 3 seconds
- Shows container hostname and ID for load balancing verification

**NGINX Start:**
- `nginx -g 'daemon off;'` - Starts NGINX in foreground mode

### Step 10: Build and Run the Application

```bash
# Build and start all services
docker-compose up --build

# Or run in background
docker-compose up --build -d
```

**Explanation:**
- `docker-compose up` - Creates and starts all services
- `--build` - Forces rebuilding of images
- `-d` - Runs in detached mode (background)

### Step 11: Access the Application

Open your browser and navigate to:
```
http://localhost:8085
```

**Explanation:**
- Port 8085 is mapped from the reverse proxy container
- The reverse proxy distributes requests across the 3 web containers

## File Structure

```
Milestone1/
├── docker-compose.yaml          # Main orchestration file
├── reverse-proxy/
│   ├── Dockerfile               # Reverse proxy container build
│   └── nginx.conf               # Load balancer configuration
├── nginx/
│   ├── Dockerfile               # Web container build
│   ├── entrypoint.sh            # Container startup script
│   └── index.html               # Initial HTML template
└── mongo-init/
    └── init.js                  # Database initialization script
```

## How It Works

1. **Startup Sequence:**
   - MongoDB starts first
   - Web containers wait for MongoDB, then start
   - Reverse proxy starts last (waits for web containers)

2. **Load Balancing:**
   - Reverse proxy receives requests on port 8085
   - Distributes requests across 3 web containers using round-robin
   - Each container has a unique hostname

3. **Dynamic Content:**
   - Each web container fetches student name from MongoDB
   - Background process updates name file every 5 seconds
   - JavaScript fetches updated name every 3 seconds
   - Cache-busting ensures fresh content on each request

4. **Container Identification:**
   - Each container displays its unique hostname and ID
   - Refreshing the page shows different containers
   - Proves load balancing is working

## Testing Load Balancing

1. **Access the application:** `http://localhost:8085`
2. **Refresh the page multiple times**
3. **Observe different container hostnames and IDs**
4. **Verify load balancing is working**

**Expected Behavior:**
- Each refresh should show a different container hostname
- Container IDs should also change
- The student name should remain consistent across containers

## Troubleshooting

### Common Issues:

1. **Port already in use:**
   ```bash
   # Check what's using port 8085
   netstat -ano | findstr :8085
   # Kill the process or change port in docker-compose.yaml
   ```

2. **Containers not starting:**
   ```bash
   # Check logs
   docker-compose logs
   # Check specific service
   docker-compose logs web
   ```

3. **Load balancing not working:**
   - Ensure cache-busting headers are working
   - Try hard refresh (Ctrl+Shift+R)
   - Check reverse proxy configuration

4. **MongoDB connection issues:**
   ```bash
   # Check if MongoDB is running
   docker-compose ps
   # Check MongoDB logs
   docker-compose logs mongo
   ```

### Useful Commands:

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs

# Stop all services
docker-compose down

# Remove all containers and volumes
docker-compose down -v

# Rebuild specific service
docker-compose build web

# Scale web service
docker-compose up --scale web=5
```

## Summary

This project demonstrates:
- **Horizontal scaling** with Docker Compose replicas
- **Load balancing** with NGINX reverse proxy
- **Database integration** with MongoDB
- **Dynamic content** that updates from database
- **Container orchestration** with proper dependencies
- **Cache management** for load balancing verification

The application successfully distributes requests across multiple containers while maintaining consistent data from the database. 