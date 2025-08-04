#!/bin/bash

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
until mongosh --host mongo --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    echo "MongoDB is not ready yet. Waiting..."
    sleep 2
done
echo "MongoDB is ready!"

# Get student name from MongoDB using mongosh
echo "Fetching student name from MongoDB..."
NAME=$(mongosh --quiet --host mongo --eval 'db = db.getSiblingDB("milestoneDB"); db.students.findOne().name')

# Check if we got a name, if not use a default
if [ -z "$NAME" ] || [ "$NAME" = "null" ]; then
    NAME="Tom Mues"
    echo "Using default name: $NAME"
else
    echo "Retrieved name: $NAME"
fi

# Get container hostname for display
HOSTNAME=$(hostname)
echo "Container hostname: $HOSTNAME"

# Create the HTML file in the nginx document root
# This overwrites the read-only mounted file
echo "Creating HTML file with dynamic content..."
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
  <head>
    <title>Milestone 1</title>
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
      }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>$NAME has reached Milestone 1!!</h1>
      <p>Congratulations on completing this milestone!</p>
      <div class="hostname">Container Hostname: $HOSTNAME</div>
    </div>
  </body>
</html>
EOF

echo "HTML file created successfully"
echo "Starting nginx..."
nginx -g 'daemon off;'
