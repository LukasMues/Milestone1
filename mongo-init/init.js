db = db.getSiblingDB("milestoneDB");
db.students.drop();
db.students.insertOne({ name: "Tom Mues" });