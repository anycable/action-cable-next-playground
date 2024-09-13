SCENARIO ?= echo
SCALE ?= 10

websocket-bench:
	websocket-bench broadcast ws://localhost:8080/cable \
		--concurrent 8 \
		--sample-size 100 \
		--step-size 200 \
		--payload-padding 200 \
		--total-steps 10 \
		--origin http://0.0.0.0 \
		--server-type=actioncable

build-k6:
	@test -x ./k6 || \
		xk6 build v0.42.0 --with github.com/anycable/xk6-cable@latest

k6: build-k6
	./k6 run scripts/k6/benchmark.js

wsdirector:
	@bundle exec wsdirector -f scripts/wsdirector/$(SCENARIO).yml -u ws://localhost:8080/cable -s $(SCALE)

bin/dist/anycable-go:
	@bin/anycable-go -v

anyt-puma:
	@bundle exec anyt --self-check

anyt-anycable: bin/dist/anycable-go
	ANYCABLE_HEADERS=cookie,x-api-token \
	bundle exec anyt -c "bin/dist/anycable-go" --target-url="ws://localhost:8080/cable"

.PHONY: websocket-bench
