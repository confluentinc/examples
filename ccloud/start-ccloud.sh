./ccloud-generate-cp-configs.sh
source delta_configs/env.delta
ccloud topic create users
docker-compose up -d

sleep 50

./submit_replicator_config.sh

