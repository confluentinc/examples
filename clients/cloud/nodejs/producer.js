const Kafka = require('node-rdkafka');
const { configFromCli } = require('./config');

async function createProducer(config) {
  const producer = new Kafka.Producer({
    'metadata.broker.list': config['bootstrap.servers'],
    'sasl.username': config['sasl.username'],
    'sasl.password': config['sasl.password'],
    'security.protocol': 'SASL_SSL',
    'sasl.mechanisms': 'PLAIN',
    'dr_cb': true
  });

  return new Promise((resolve, reject) => {
    producer
      .on('ready', () => resolve(producer))
      .on('event.error', (err) => {
        console.warn('event.error', err);
        reject(err);
    });

    producer.connect();
  });
}

function range(length) {
  return Array.from(Array(length).keys());
}

async function produceExample() {
  const config = await configFromCli();

  if (config.usage) {
    return console.log(config.usage);
  }

  const producer = await createProducer(config);

  range(10).forEach((count) => {
    const key = 'alice';
    const value = Buffer.from(JSON.stringify({ count }));
    
    console.log(`Producing record ${key}\t${value}`);

    producer.produce(config.topic, -1, value, key);
  });

  producer.flush(500, () => {
    producer.disconnect();
  });
}

produceExample()
  .catch((err) => {
    console.error(`Something went wrong:\n${err}`);
    process.exit(1);
  });
