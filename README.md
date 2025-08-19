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
- [AI Prompts and Responses](#ai-prompts-and-responses)
- [AI Reflection](#ai-reflection)

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
    container_name: contnginx-m1-lm
    ports:
      - "8085:80"  # Public entrypoint - same as before
    depends_on:
      - web1
      - web2
      - web3
    networks:
      - milestone-net

  # Multiple NGINX Web Containers (Individual Services)
  web1:
    build: ./nginx
    container_name: contweb-m1-lm1
    depends_on:
      - mongo
    networks:
      - milestone-net

  web2:
    build: ./nginx
    container_name: contweb-m1-lm2
    depends_on:
      - mongo
    networks:
      - milestone-net

  web3:
    build: ./nginx
    container_name: contweb-m1-lm3
    depends_on:
      - mongo
    networks:
      - milestone-net

  # MongoDB (Single Instance)
  mongo:
    image: mongo
    container_name: contmongo-m1-lm
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
   - `container_name: contnginx-m1-lm` - Gives the container a specific name
   - `ports: - "8085:80"` - Maps host port 8085 to container port 80
   - `depends_on: - web1, web2, web3` - Ensures all web services start before reverse-proxy
   - `networks: - milestone-net` - Connects to custom network

2. **web1, web2, web3 services:**
   - `build: ./nginx` - Builds from the nginx directory
   - `container_name: contweb-m1-lm1, contweb-m1-lm2, contweb-m1-lm3` - Individual container names
   - `depends_on: - mongo` - Ensures MongoDB starts first
   - Each service represents one web container instance

3. **mongo service:**
   - `image: mongo` - Uses official MongoDB image
   - `container_name: contmongo-m1-lm` - Gives the container a specific name
   - `volumes:` - Mounts data directory and initialization script
   - `./mongo-init/init.js:/docker-entrypoint-initdb.d/init.js:ro` - Mounts init script as read-only

**Networks and Volumes:**
- `milestone-net` - Custom network for service communication
- `mongo-data` - Persistent volume for MongoDB data (survives container restarts)

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
        server web1:80;
        server web2:80;
        server web3:80;
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
- `server web1:80, web2:80, web3:80` - Points to all three web services on port 80

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

# Copy the nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

**Explanation:**
- `FROM nginx:alpine` - Uses lightweight Alpine Linux NGINX image
- `COPY nginx.conf /etc/nginx/nginx.conf` - Copies our custom configuration
- `EXPOSE 80` - Documents that the container listens on port 80
- `CMD ["nginx", "-g", "daemon off;"]` - Starts NGINX in foreground mode

### Step 6: Create MongoDB Initialization Script

Create `mongo-init/init.js`:

```javascript
db = db.getSiblingDB("milestoneDB");
db.students.drop();
db.students.insertOne({ name: "Lukas Mues" });
```

**Explanation:**
- `db.getSiblingDB("milestoneDB")` - Creates/accesses the milestoneDB database
- `db.students.drop()` - Removes any existing data to ensure clean state
- `db.students.insertOne({ name: "Lukas Mues" })` - Inserts a student document with just the name
- **Important**: This script only runs on first startup when the volume is empty
- On subsequent restarts, the data persists and this script is NOT executed

### Step 7: Create NGINX Web Container Files

Create `nginx/Dockerfile`:

```dockerfile
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
```

**Explanation:**
- `FROM ubuntu:24.04` - Uses Ubuntu 24.04 as base image
- `RUN apt update && apt install -y nginx curl wget gnupg` - Installs NGINX and required tools
- `RUN wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -` - Adds MongoDB GPG key
- `echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse"` - Adds MongoDB repository
- `RUN apt update && apt install -y mongodb-mongosh` - Installs MongoDB shell (mongosh)
- `WORKDIR /var/www/html` - Sets the working directory
- `COPY entrypoint.sh /entrypoint.sh` - Copies our startup script
- `RUN chmod +x /entrypoint.sh` - Makes the script executable
- `EXPOSE 80` - Documents that the container listens on port 80
- `CMD ["/entrypoint.sh"]` - Runs the entrypoint script

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

## Container Names

The application uses the following container names:
- **Reverse Proxy**: `contnginx-m1-lm`
- **Web Containers**: `contweb-m1-lm1`, `contweb-m1-lm2`, `contweb-m1-lm3`
- **MongoDB**: `contmongo-m1-lm`

## How It Works

1. **Startup Sequence:**
   - MongoDB starts first
   - Web containers wait for MongoDB, then start
   - Reverse proxy starts last (waits for web containers)

2. **Load Balancing:**
   - Reverse proxy receives requests on port 8085
   - Distributes requests across 3 web containers (web1, web2, web3) using round-robin
   - Each container has a unique hostname and custom container name

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
- Container names will be: `contweb-m1-lm1`, `contweb-m1-lm2`, `contweb-m1-lm3`

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
   docker-compose logs web1
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
docker-compose build web1

# Check specific container logs
docker-compose logs contweb-m1-lm1
```

## AI Prompts and Responses

### Key Prompts and AI Responses Used in Development:

**Prompt 1:** "when i refresh my page the container is not changing so something is wrong with the loadbalancing"

**AI Response:** Identified browser caching as the main issue and provided cache-busting solutions including:
- Added cache-busting headers in nginx.conf
- Added cache-busting meta tags in HTML
- Added timestamp parameters to JavaScript fetch calls

**Prompt 2:** "alles werkt nu, kun je dingen wegladen om minder code te hebben en minder nutteloze code"

**AI Response:** Cleaned up the code by:
- Removing unnecessary echo statements
- Removing verbose comments
- Compressing code while maintaining functionality
- Removing unused variables

**Prompt 3:** "i have to use contnginx2-m1-lm for your nginx container and contmongo-m1-lm for your MongoDBcontainer. change all he container names"

**AI Response:** Updated container names and explained the difference between using individual services vs. replicas for custom naming.

**Prompt 4:** "i want the names of the the load balancing containers contweb-m1-lm1 lm2 lm3"

**AI Response:** Changed from using `deploy: replicas: 3` to individual services (web1, web2, web3) to allow custom container names.


## AI Reflection

### How AI Helped Me:

**1. Problem Solving and Debugging:**
The AI was instrumental in identifying and fixing the load balancing issue. When I noticed containers weren't changing on refresh, the AI immediately identified browser caching as the root cause and provided specific cache-busting solutions that worked perfectly.

**2. Code Optimization:**
The AI helped me clean up unnecessary code and comments while maintaining full functionality. This made the codebase more professional and easier to maintain.

**3. Container Orchestration Understanding:**
Through our interactions, I learned the difference between using `deploy: replicas` vs. individual services for custom container naming. The AI explained why individual services were needed for my specific naming requirements.


### What I Learned:

**1. Load Balancing Best Practices:**
- Cache-busting is essential for load balancing verification
- Browser caching can mask load balancing issues
- Proper headers and meta tags are crucial

**2. Docker Compose Architecture:**
- Understanding service dependencies and startup order
- Difference between replicas and individual services
- Custom container naming strategies

**3. Data Persistence:**
- How Docker volumes work independently of containers
- MongoDB initialization script behavior
- When data persists vs. when it gets reset



The AI acted as both a coding partner and a learning resource, helping me understand not just how to fix issues, but why certain solutions work and what best practices to follow. This collaborative approach significantly improved my understanding of Docker, load balancing, and container orchestration.

## Summary

This project demonstrates:
- **Horizontal scaling** with individual Docker Compose services
- **Load balancing** with NGINX reverse proxy
- **Database integration** with MongoDB
- **Dynamic content** that updates from database
- **Container orchestration** with proper dependencies
- **Cache management** for load balancing verification
- **Custom container naming** for easy identification
- **Data persistence** with Docker volumes for reliable data storage

The application successfully distributes requests across multiple containers while maintaining consistent data from the database. The MongoDB data persists across container restarts, ensuring your student information is always available. 