# 🚀 Milestone 1 - Load Balanced Setup

A Docker-based web application with horizontal scaling and load balancing that demonstrates dynamic content generation with MongoDB integration.

## 📋 **Project Overview**

This project consists of:
- **1 Reverse Proxy container** (NGINX) for load balancing
- **3 NGINX web containers** (Ubuntu 24.04) serving dynamic HTML content
- **1 MongoDB container** with persistent data storage
- Dynamic name retrieval from MongoDB at startup
- Container hostname display for load balancing verification

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Reverse       │    │   NGINX Web     │    │    MongoDB      │
│   Proxy         │───►│   Containers    │◄──►│   Container     │
│   (Port 8085)   │    │   (3 instances) │    │   (Internal)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 **Quick Start**

### **Prerequisites**
- Docker
- Docker Compose

### **Run the Application**
```bash
# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up --build -d
```

### **Access the Application**
- **URL**: http://localhost:8085
- The page will display your name from MongoDB and the container hostname
- **Refresh multiple times** to see different container hostnames (load balancing demo)

## 📁 **Project Structure**

```
Milestone1/
├── docker-compose.yaml      # Main orchestration file
├── reverse-proxy/
│   ├── Dockerfile          # Reverse proxy container definition
│   └── nginx.conf          # Load balancer configuration
├── nginx/
│   ├── Dockerfile          # NGINX container definition
│   ├── entrypoint.sh       # Startup script with MongoDB integration
│   └── index.html          # Template HTML file
├── mongo-init/
│   └── init.js             # MongoDB initialization script
└── README.md               # This file
```

## 🔧 **How It Works**

### **1. Load Balancing Architecture**
1. Reverse proxy receives all incoming requests on port 8085
2. Distributes traffic across 3 NGINX web containers using round-robin
3. Each web container connects to MongoDB independently
4. Different container hostnames prove load balancing is working

### **2. Container Startup Process**
1. Reverse proxy starts and waits for web containers
2. Multiple NGINX containers start and wait for MongoDB
3. Each container connects to MongoDB and retrieves student name
4. Generates dynamic HTML with name and unique hostname
5. Starts NGINX web server

### **3. Dynamic Content Generation**
- Student name is fetched from MongoDB
- Container hostname is captured for load balancing verification
- HTML is generated with current timestamp
- Enhanced styling shows load balancing status

### **4. Data Persistence**
- MongoDB data is stored in a Docker volume
- Student information persists between container restarts
- Initial data is loaded via `mongo-init/init.js`

## 🛠️ **Development**

### **Rebuild After Changes**
```bash
# Rebuild and restart
docker-compose down
docker-compose up --build
```

### **View Logs**
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs reverse-proxy
docker-compose logs web
docker-compose logs mongo
```

### **Access Container Shell**
```bash
# Reverse proxy container
docker-compose exec reverse-proxy sh

# NGINX container (first instance)
docker-compose exec web bash

# MongoDB container
docker-compose exec mongo mongosh
```

## 🧪 **Testing**

### **Health Check**
```bash
# Test the web application
curl http://localhost:8085

# Check container status
docker-compose ps
```

### **Load Balancing Test**
```bash
# Test load balancing by refreshing the page multiple times
# Or use curl to see different hostnames
for i in {1..10}; do curl -s http://localhost:8085 | grep "Container Hostname"; sleep 1; done
```

### **Verify MongoDB Connection**
```bash
# Connect to MongoDB
docker-compose exec mongo mongosh

# Check the database
use milestoneDB
db.students.find()
```

## 🧹 **Cleanup**

### **Stop and Remove**
```bash
# Stop containers
docker-compose down

# Remove containers and volumes
docker-compose down -v
```

## 📊 **Features**

- ✅ **Horizontal Scaling**: 3 NGINX instances for high availability
- ✅ **Load Balancing**: Round-robin distribution via reverse proxy
- ✅ **Dynamic Content**: Name from MongoDB + container hostname
- ✅ **Persistent Data**: MongoDB volume for data storage
- ✅ **Health Monitoring**: Container status and logs
- ✅ **Easy Deployment**: One-command startup
- ✅ **Development Ready**: Easy rebuild and testing

## 🎯 **Success Criteria**

When you visit http://localhost:8085, you should see:
- Your name from the database
- The container hostname (changes on refresh)
- A clean, modern web page
- Confirmation that load balancing is active

**Bonus Feature Demo**: Refresh the page multiple times to see different container hostnames, proving that load balancing is working across multiple instances.

## 🔄 **Bonus Feature: Horizontal Scaling**

### **What's New**
- **Reverse Proxy**: NGINX load balancer distributing traffic
- **Multiple Instances**: 3 NGINX web containers running simultaneously
- **Load Balancing**: Round-robin distribution of requests
- **Visual Confirmation**: Different container hostnames on each refresh

### **How to Test**
1. Start the application: `docker-compose up --build`
2. Visit http://localhost:8085
3. Refresh the page multiple times
4. Observe the container hostname changing, proving load balancing works

### **Benefits**
- **High Availability**: Multiple instances ensure service continuity
- **Better Performance**: Distributed load across multiple containers
- **Scalability**: Easy to add more instances by changing `replicas` in docker-compose.yaml
- **Fault Tolerance**: If one container fails, others continue serving

This setup provides enterprise-grade scalability while maintaining the simplicity and reliability of the original design. 