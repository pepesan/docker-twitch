## Lanzamieto del los contenedores de MongoDB Shards
docker compose up -d

## Creación del Replica Set de Config Servers

mongosh --port 27018

rs.initiate({
    _id: "csrs",
    configsvr: true,
    members: [
        { _id: 0, host: "configsvr1:27017" },
        { _id: 1, host: "configsvr2:27017" },
        { _id: 2, host: "configsvr3:27017" }
        ]
});

rs.status()
exit

## Creación del Replica Set del Shard 1
mongosh --port 27019
rs.initiate({
    _id: "shard1",
    members: [
        { _id: 0, host: "shard1:27017" }
        ]
});
rs.status()
exit
## Creación del Replica Set del Shard 2
mongosh --port 27020
rs.initiate({
_id: "shard2",
members: [
{ _id: 0, host: "shard2:27017" }
]
})
rs.status()
exit

## Añadir los Shards al Router
mongosh --port 27017
sh.addShard("shard1/shard1:27017");
sh.addShard("shard2/shard2:27017");




