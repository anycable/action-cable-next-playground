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

.PHONY: websocket-bench
