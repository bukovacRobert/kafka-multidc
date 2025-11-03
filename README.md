# Kafka Multi-DC Sync (MongoDB → Kafka → MongoDB)

Minimal local setup to sync MongoDB data across DCs using Kafka Connect + Debezium and the MongoDB Kafka Sink.

## What this does (high level)

* **DE1 → per-DC**: Debezium **source** reads `gamedb.{tenants, tenantGames, partners}` and **routes** records to DC-specific topics based on `value.dc`
  (`br-1` → `dc-br1.*`, `sg-1` → `dc-sg1.*`).
  *Deletes are ignored (upsert-only).*

* **Rounds fan-in**: Debezium **sources** in BR1/SG1 read `readdb.{gameRounds, roundsArchive}` and **RegexRouter** maps them to two aggregate topics:
  `readdb.game-rounds-active`, `readdb.game-rounds-archive`.
  *Deletes are dropped.*

* **Sinks**: MongoDB **sink** writes:

    * DC datasets to each DC’s `gamedb` (`dc-br1.*` → `gamedb.{tenants,tenantGames,partners}`).
    * Rounds topics to `readdb.{gameRounds, roundsArchive}`.
      *Upsert via `_id` (no deletes).*

## Repo layout

* `docker-compose.yml` – Kafka, ZooKeeper, MongoDBs, Kafka Connect.
* `init-replica-sets.sh` – initializes Mongo replica sets (local).
* `dev.sh` – register connectors

## Quick start (local)

```bash
# 1) Bring everything up
docker-compose up -d

# 2) Init Mongo replica sets
./init-replica-sets.sh

# 3) Register connectors
./dev.sh 
```

## Testing (local)


```bash
# Insert 3 tenants

docker exec -it mongodb-de1 mongosh --quiet --eval '
db.getSiblingDB("gamedb").tenants.insertOne({
  _id: "tenant-cbr-e2e-20",
  name: "From DE1 via CBR end-to-end",
  dc: "br-1",
  region: "LATAM",
  status: "active",
  createdAt: new Date()
})
'


docker exec -it mongodb-de1 mongosh --quiet --eval '
db.getSiblingDB("gamedb").tenants.insertOne({
  _id: "tenant-cbr-e2e-22",
  name: "From DE1 via CBR end-to-end",
  dc: "de-1",
  region: "LATAM",
  status: "active",
  createdAt: new Date()
})
'

docker exec -it mongodb-de1 mongosh --quiet --eval '
db.getSiblingDB("gamedb").tenants.insertOne({
  _id: "tenant-cbr-e2e-21",
  name: "From DE1 via CBR end-to-end",
  dc: "sg-1",
  region: "LATAM",
  status: "active",
  createdAt: new Date()
})
'

# Check 3 tenants
 

docker exec -it mongodb-de1 mongosh --quiet --eval 'db.getSiblingDB("gamedb").tenants.find().pretty()'

docker exec -it mongodb-br1 mongosh --quiet --eval 'db.getSiblingDB("gamedb").tenants.find().pretty()'

docker exec -it mongodb-sg1 mongosh --quiet --eval 'db.getSiblingDB("gamedb").tenants.find().pretty()'

# Update tenant


docker exec -it mongodb-de1 mongosh --quiet --eval '
db.getSiblingDB("gamedb").tenants.updateOne(
  { _id: "tenant-cbr-e2e-20" },
  { $set: { region: "OVO JE GRAD BEOGRAD" } }
)'


# Insert one round (br)

docker exec -it mongodb-br1 mongosh --quiet --eval '
db.getSiblingDB("readdb").gameRounds.insertOne({
  _id: "round-br1-101",
  tenantId: "tenant-br1-1",
  gameId: "br1-game-1",
  dc: "br-1",
  state: "finished",
  win: 333,
  updatedAt: new Date()
})'

# Check one round (read db)

docker exec -it mongodb-readdb mongosh --quiet --eval \
'db.getSiblingDB("readdb").gameRounds.find().pretty()'



```
