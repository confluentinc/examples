# rmoff / 13 Jun 2018
from slackclient import SlackClient
from confluent_kafka import Consumer, KafkaError
import json
import time
import os,sys

token = os.environ.get('SLACK_API_TOKEN')
if token is None:
	print('\n\n*******\nYou need to set your Slack API token in the SLACK_API_TOKEN environment variable\n\nExiting.\n\n*******\n')
	sys.exit(1)

sc = SlackClient(token)

# Set 'auto.offset.reset': 'smallest' if you want to consume all messages
# from the beginning of the topic
settings = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'python_kafka_notify.py',
    'default.topic.config': {'auto.offset.reset': 'largest'}
}
c = Consumer(settings)

c.subscribe(['UNHAPPY_PLATINUM_CUSTOMERS'])

try:
    while True:
        msg = c.poll(0.1)
        time.sleep(5)
        if msg is None:
            continue
        elif not msg.error():
            print('Received message: {0}'.format(msg.value()))
            if msg.value() is None:
                continue
            try:
                app_msg = json.loads(msg.value().decode())
            except:
                app_msg = json.loads(msg.value())
            try:
                email=app_msg['EMAIL']
                message=app_msg['MESSAGE']
		channel='unhappy-customers'
		text=('`%s` just left a bad review :disappointed:\n> %s\n\n_Please contact them immediately and see if we can fix the issue *right here, right now*_' % (email, message))
                print('\nSending message "%s" to channel %s' % (text,channel))
            except:
                print('Failed to get channel/text from message')
                channel='general'
                text=msg.value()
            try:
                sc_response = sc.api_call('chat.postMessage', channel=channel,
                            text=text, username='KSQL Notifications',
                            icon_emoji=':rocket:')
                if not sc_response['ok']:
                    print('\t** FAILED: %s' % sc_response['error'])
            except Exception as e:
                print(type(e))
                print(dir(e))
        elif msg.error().code() == KafkaError._PARTITION_EOF:
            print('End of partition reached {0}/{1}'
                  .format(msg.topic(), msg.partition()))
        else:
            print('Error occured: {0}'.format(msg.error().str()))

except Exception as e:
    print(type(e))
    print(dir(e))

finally:
    c.close()
