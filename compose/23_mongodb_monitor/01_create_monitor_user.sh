#!/bin/bash

docker exec -it mongo mongosh -u root -p rootpass --authenticationDatabase admin --eval '
db.getSiblingDB("admin").createUser({
  user: "monitor",
  pwd: "monitorpass",
  roles: [
    { role: "clusterMonitor", db: "admin" },
    { role: "read", db: "local" }
  ]
})
'

docker exec -it mongo mongosh -u monitor -p monitorpass --authenticationDatabase admin --eval '
print("Auth OK");
db.runCommand({ serverStatus: 1 });
db.getSiblingDB("local").getCollectionNames();
'

