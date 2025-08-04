#!/bin/bash

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
until mongosh --host mongo --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    echo "MongoDB is not ready yet. Waiting..."
    sleep 2
done
echo "MongoDB is ready!"

# Function to get current name from MongoDB
get_current_name() {
    NAME=$(mongosh --quiet --host mongo --eval 'db = db.getSiblingDB("milestoneDB"); db.students.findOne().name')
    if [ -z "$NAME" ] || [ "$NAME" = "null" ]; then
        NAME="Tom Mues"
    fi
    echo "$NAME"
}

# Get initial student name from MongoDB using mongosh
echo "Fetching initial student name from MongoDB..."
INITIAL_NAME=$(get_current_name)
echo "Retrieved initial name: $INITIAL_NAME"

# Get container hostname and additional info
HOSTNAME=$(hostname)
CONTAINER_ID=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "Container hostname: $HOSTNAME"
echo "Container ID: $CONTAINER_ID"
echo "Startup time: $TIMESTAMP"

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
UPDATE_PID=$!

# Create the HTML file in the nginx document root
# This overwrites the read-only mounted file
echo "Creating HTML file with dynamic content..."
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Milestone 1 - Load Balanced</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        text-align: center;
        margin-top: 50px;
        background-color: #f0f0f0;
      }
      h1 {
        color: #333;
        font-size: 2.5em;
      }
      .container {
        background-color: white;
        padding: 40px;
        border-radius: 10px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        max-width: 600px;
        margin: 0 auto;
      }
      .hostname {
        color: #666;
        font-size: 1.2em;
        margin-top: 20px;
        padding: 10px;
        background-color: #e8f4f8;
        border-radius: 5px;
      }
      .info {
        color: #888;
        font-size: 0.9em;
        margin-top: 15px;
        font-style: italic;
      }
      .timestamp {
        color: #999;
        font-size: 0.8em;
        margin-top: 10px;
      }
      .status {
        color: #2196F3;
        font-weight: bold;
        margin-top: 15px;
        padding: 8px;
        background-color: #E3F2FD;
        border-radius: 5px;
      }
    </style>
    <script>
      // Function to fetch current name from file
      async function fetchCurrentName() {
        try {
          const response = await fetch('/current_name.txt');
          const name = await response.text();
          if (name && name.trim()) {
            document.getElementById('student-name').textContent = name.trim();
          }
        } catch (error) {
          console.log('Could not fetch updated name, using initial name');
        }
      }
      
      // Fetch name when page loads and every 3 seconds
      window.onload = function() {
        fetchCurrentName();
        setInterval(fetchCurrentName, 3000);
      };
    </script>
  </head>
  <body>
    <div class="container">
      <h1><span id="student-name">$INITIAL_NAME</span> has reached Milestone 1!!</h1>
      
      <div class="hostname">
        <strong>Container Hostname:</strong> $HOSTNAME<br>
        <strong>Container ID:</strong> $CONTAINER_ID
      </div>
      
      <div class="timestamp">
        Generated at: $TIMESTAMP
      </div>
    </div>
  </body>
</html>
EOF

# Create initial name file
echo "$INITIAL_NAME" > /var/www/html/current_name.txt

echo "HTML file created successfully"
echo "Starting nginx..."
nginx -g 'daemon off;'
