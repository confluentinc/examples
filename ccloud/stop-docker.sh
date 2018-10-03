docker-compose down

for v in $(docker volume ls -q --filter="dangling=true"); do
        docker volume rm "$v"
done

topics=$(ccloud topic list)

topics_to_delete="pageviews pageviews.replica users pageviews_enriched_r8_r9 PAGEVIEWS_FEMALE PAGEVIEWS_REGIONS"
for topic in $topics_to_delete
do
  echo $topics | grep $topic &>/dev/null
  if [[ $? == 0 ]]; then
    ccloud topic delete $topic
  fi
done
