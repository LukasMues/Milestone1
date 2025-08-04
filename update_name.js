db = db.getSiblingDB("milestoneDB");
db.students.updateOne({}, {$set: {name: "Lukas Mues"}});
print("Updated name to: Lukas Mues"); 