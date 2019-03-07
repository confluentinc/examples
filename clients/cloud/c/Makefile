BINS=consumer producer

SRCS=common.c json.c
LIBS=-lrdkafka -lm


all: $(BINS)

consumer: consumer.c $(SRCS)
	$(CC) $(CPPFLAGS) $(LDFLAGS) $^ -o $@ $(LIBS)

producer: producer.c $(SRCS)
	$(CC) $(CPPFLAGS) $(LDFLAGS) $^ -o $@ $(LIBS)


clean:
	rm -f *.o $(BINS)
