
PUSH_PREFIX ?= cnfldemos
CONTAINER_NAME ?= ccloud-observability-client
VERSION ?= 0.1.0


build-image:
	docker build -t $(PUSH_PREFIX)/$(CONTAINER_NAME):$(VERSION) .

push-image: build-image
	docker push $(PUSH_PREFIX)/$(CONTAINER_NAME)
