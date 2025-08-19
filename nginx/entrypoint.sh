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
