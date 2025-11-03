#!/usr/bin/env bash
set -e

function init_rs() {
  local cname=$1
  local rsname=$2
  echo "Initializing $cname ($rsname)..."
  docker exec -i "$cname" mongosh --quiet <<EOF
try {
  rs.initiate({
    _id: "$rsname",
    members: [{ _id: 0, host: "$cname:27017" }]
  })
} catch (e) {
  // already initiated
}
EOF
}

init_rs mongodb-de1 rs0
init_rs mongodb-br1 rs1
init_rs mongodb-sg1 rs2
init_rs mongodb-readdb rs3

echo "All replica sets initialized."
