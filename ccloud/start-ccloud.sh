./ccloud-generate-cp-configs.sh
source delta_configs/env.delta
ccloud topic create users
docker-compose up -d

sleep 30

./submit_replicator_config.sh
