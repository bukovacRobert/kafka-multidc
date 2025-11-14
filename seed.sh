#!/usr/bin/env bash
set -e

echo "=== Seeding DE1: tenants, tenantGames, partners ==="
docker exec -i mongodb-de1 mongosh --quiet <<'EOF'
db = db.getSiblingDB("gamedb")

db.tenants.insertMany([
  {
    _id: ObjectId(),
    dc: "br-1",
    tenantId: "TENANT-BR1-001",
    name: "Tenant BR1 (should go to br1)",
    status: "ACTIVE"
  },
  {
    _id: ObjectId(),
    dc: "sg-1",
    tenantId: "TENANT-SG1-001",
    name: "Tenant SG1 (should go to sg1)",
    status: "ACTIVE"
  },
  {
    _id: ObjectId(),
    dc: "de-1",
    tenantId: "TENANT-DE1-IGNORED",
    name: "Tenant DE1 (should NOT be forwarded)",
    status: "ACTIVE"
  }
])

db.tenantGames.insertMany([
  {
    _id: ObjectId(),
    dc: "br-1",
    tenantId: "TENANT-BR1-001",
    gameCode: "GAME-BR1-01",
    enabled: true
  },
  {
    _id: ObjectId(),
    dc: "sg-1",
    tenantId: "TENANT-SG1-001",
    gameCode: "GAME-SG1-01",
    enabled: true
  },
  {
    _id: ObjectId(),
    dc: "de-1",
    tenantId: "TENANT-DE1-IGNORED",
    gameCode: "GAME-DE1-IGNORED",
    enabled: true
  }
])

db.partners.insertMany([
  {
    _id: ObjectId(),
    dc: "br-1",
    partnerId: "PARTNER-BR1-001",
    name: "Partner BR1 (should go to br1)",
    level: "GOLD"
  },
  {
    _id: ObjectId(),
    dc: "sg-1",
    partnerId: "PARTNER-SG1-001",
    name: "Partner SG1 (should go to sg1)",
    level: "SILVER"
  },
  {
    _id: ObjectId(),
    dc: "de-1",
    partnerId: "PARTNER-DE1-IGNORED",
    name: "Partner DE1 (should NOT be forwarded)",
    level: "BRONZE"
  }
])

print("Seeded DE1 ops collections (tenants, tenantGames, partners)")
EOF

echo "=== Seeding DE1 archives (roundsArchive, transactionsArchive) ==="
docker exec -i mongodb-de1 mongosh --quiet <<'EOF'
db = db.getSiblingDB("gamedb")

db.roundsArchive.insertOne({
  _id: ObjectId(),
  dc: "de-1",
  roundId: "ROUND-DE1-001",
  tenantId: "TENANT-DE1-IGNORED",
  gameCode: "GAME-DE1-ARCH",
  betAmount: 1.23,
  winAmount: 4.56,
  currency: "EUR",
  createdAt: ISODate()
})

db.transactionsArchive.insertOne({
  _id: ObjectId(),
  dc: "de-1",
  transactionId: "TX-DE1-001",
  playerId: "PLAYER-DE1-001",
  tenantId: "TENANT-DE1-IGNORED",
  amount: 10.00,
  type: "BET",
  status: "SETTLED",
  createdAt: ISODate()
})

print("Seeded DE1 archives")
EOF

echo "=== Seeding BR1 archives (roundsArchive, transactionsArchive) ==="
docker exec -i mongodb-br1 mongosh --quiet <<'EOF'
db = db.getSiblingDB("gamedb")

db.roundsArchive.insertOne({
  _id: ObjectId(),
  dc: "br-1",
  roundId: "ROUND-BR1-001",
  tenantId: "TENANT-BR1-001",
  gameCode: "GAME-BR1-ARCH",
  betAmount: 2.00,
  winAmount: 0.50,
  currency: "BRL",
  createdAt: ISODate()
})

db.transactionsArchive.insertOne({
  _id: ObjectId(),
  dc: "br-1",
  transactionId: "TX-BR1-001",
  playerId: "PLAYER-BR1-001",
  tenantId: "TENANT-BR1-001",
  amount: 5.00,
  type: "WIN",
  status: "SETTLED",
  createdAt: ISODate()
})

print("Seeded BR1 archives")
EOF

echo "=== Seeding SG1 archives (roundsArchive, transactionsArchive) ==="
docker exec -i mongodb-sg1 mongosh --quiet <<'EOF'
db = db.getSiblingDB("gamedb")

db.roundsArchive.insertOne({
  _id: ObjectId(),
  dc: "sg-1",
  roundId: "ROUND-SG1-001",
  tenantId: "TENANT-SG1-001",
  gameCode: "GAME-SG1-ARCH",
  betAmount: 3.33,
  winAmount: 7.77,
  currency: "SGD",
  createdAt: ISODate()
})

db.transactionsArchive.insertOne({
  _id: ObjectId(),
  dc: "sg-1",
  transactionId: "TX-SG1-001",
  playerId: "PLAYER-SG1-001",
  tenantId: "TENANT-SG1-001",
  amount: 20.00,
  type: "BET",
  status: "SETTLED",
  createdAt: ISODate()
})

print("Seeded SG1 archives")
EOF

echo "=== Done seeding test data ==="
echo "Now you can check:"
echo "  - br1/sg1 gamedb.tenants/tenantGames/partners"
echo "  - readdb.roundsArchive / readdb.transactionsArchive"
