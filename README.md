# Kafka Multi-DC Sync (MongoDB → Kafka → MongoDB)

Minimal local setup to sync MongoDB data across DCs using Kafka Connect + Debezium and the MongoDB Kafka Sink.

DCs:

- **de-1** – operational Mongo (`mongodb-de1`, DB: `gamedb`)
- **br-1** – operational Mongo (`mongodb-br1`, DB: `gamedb`)
- **sg-1** – operational Mongo (`mongodb-sg1`, DB: `gamedb`)
- **readdb** – central read DB (`mongodb-readdb`, DB: `readdb`)

---

## Repo layout

- `docker-compose.yml` – Kafka, ZooKeeper, MongoDBs, Kafka Connect.
- `init-replica-sets.sh` – initializes Mongo replica sets (local).
- `dev.sh` – registers connectors (Debezium + Mongo sinks).
- `seed.sh` – seeds test data into Mongo so you can verify the pipeline.
- `connectors/` – JSON configs for source & sink connectors (de-1, br-1, sg-1, readdb).

---

## Quick start (local)

```bash
# 1) Bring everything up
docker-compose up -d

# 2) Init Mongo replica sets
./init-replica-sets.sh

# 3) Register connectors (Debezium + Mongo sinks)
./dev.sh

# 4) Seed test data 
./seed.sh
```

---

## ✅ Verification

After running the seed script, verify that all MongoDB instances contain the expected documents.

### Data Distribution Overview

| Database | Expected Content |
|---|---|
| **de-1** | All documents from de-1, br-1, and sg-1 |
| **br-1** | Only documents where `dc = "br-1"` |
| **sg-1** | Only documents where `dc = "sg-1"` |
| **readdb** | Archives from all 3 DCs |

#### DE-1 
**Expected:** Contains **all documents** from all DCs

```bash
docker exec -it mongodb-de1 mongosh --quiet --eval '
  db = db.getSiblingDB("gamedb");
  print("========== DE-1 TENANTS ==========");
  print("Total count: " + db.tenants.countDocuments({}));
  print("\nDocuments:");
  printjson(db.tenants.find().toArray());
'
```

#### BR-1
**Expected:** Only documents with `dc = "br-1"`

```bash
docker exec -it mongodb-br1 mongosh --quiet --eval '
  db = db.getSiblingDB("gamedb");
  print("========== BR-1 TENANTS ==========");
  print("Total count: " + db.tenants.countDocuments({}));
  print("Filter: dc = \"br-1\"");
  print("\nDocuments:");
  printjson(db.tenants.find().toArray());
'
```

#### SG-1 
**Expected:** Only documents with `dc = "sg-1"`

```bash
docker exec -it mongodb-sg1 mongosh --quiet --eval '
  db = db.getSiblingDB("gamedb");
  print("========== SG-1 TENANTS ==========");
  print("Total count: " + db.tenants.countDocuments({}));
  print("Filter: dc = \"sg-1\"");
  print("\nDocuments:");
  printjson(db.tenants.find().toArray());
'
```

#### ReadDB 
**Expected:** Archives from all 3 DCs (de-1, br-1, sg-1)

```bash
docker exec -it mongodb-readdb mongosh --quiet --eval '
  db = db.getSiblingDB("readdb");
  print("========== READDB ARCHIVES ==========");
  
  print("\n Rounds Archive:");
  print("Total count: " + db.roundsArchive.countDocuments({}));
  printjson(db.roundsArchive.find().toArray());
  
  print("\n Transactions Archive:");
  print("Total count: " + db.transactionsArchive.countDocuments({}));
  printjson(db.transactionsArchive.find().toArray());
'
```

### 🔍 Quick Verification Script

Run all verifications at once:

```bash
#!/bin/bash
echo "🔍 Verifying all MongoDB instances..."
echo ""

# DE-1
echo " DE-1 (should have ALL documents):"
docker exec -it mongodb-de1 mongosh --quiet --eval 'db.getSiblingDB("gamedb").tenants.countDocuments({})'

# BR-1
echo " BR-1 (should have only br-1 documents):"
docker exec -it mongodb-br1 mongosh --quiet --eval 'db.getSiblingDB("gamedb").tenants.countDocuments({dc: "br-1"})'

# SG-1
echo " SG-1 (should have only sg-1 documents):"
docker exec -it mongodb-sg1 mongosh --quiet --eval 'db.getSiblingDB("gamedb").tenants.countDocuments({dc: "sg-1"})'

# ReadDB
echo "📚 ReadDB Archives:"
docker exec -it mongodb-readdb mongosh --quiet --eval '
  db = db.getSiblingDB("readdb");
  print("  Rounds: " + db.roundsArchive.countDocuments({}));
  print("  Transactions: " + db.transactionsArchive.countDocuments({}));
'
```

---
