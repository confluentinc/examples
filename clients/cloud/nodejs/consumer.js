const Kafka = require('node-rdkafka');
const { configFromCli } = require('./config');

function createConsumer(config) {
  const consumer = new Kafka.KafkaConsumer({
    'metadata.broker.list': config['bootstrap.servers'],
    'sasl.username': config['sasl.username'],
    'sasl.password': config['sasl.password'],
    'security.protocol': 'SASL_SSL',
    'sasl.mechanisms': 'PLAIN',
    'group.id': 'node-example-group-1',
    'auto.offset.reset': 'earliest'
  });

  return new Promise((resolve, reject) => {
    consumer
      .on('ready', () => resolve(consumer))
      .on('data', ({topic, offset, partition, key, value}) =>
        console.log(`Received record from topic ${topic} partition ${partition} @ ${offset}: ${key.toString()}\t${value.toString()}`));

    consumer.connect();
  });
}

async function consumerExample() {
  const config = await configFromCli();

  if (config.usage) {
    return console.log(config.usage);
  }

  const consumer = await createConsumer(config);

  consumer.subscribe([config.topic]);
  consumer.consume();
}

consumerExample()
  .catch((err) => {
    console.error(`Something went wrong:\n${err}`);
    process.exit(1);
  });
