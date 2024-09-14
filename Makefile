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
	@bundle exec anyt --self-check --require=scripts/anyt/rails/*.rb

anyt-anycable: bin/dist/anycable-go
	ANYCABLE_HEADERS=cookie,x-api-token \
	bundle exec anyt -c "bin/dist/anycable-go" --target-url="ws://localhost:8080/cable"

anyt-iodine:
	@bundle exec anyt --self-check --require="{lib/servers/iodine.rb,scripts/anyt/rails/*.rb}" \
		--rails-command="bundle exec iodine scripts/anyt/iodine.ru -p 9292 -t 5 -w 2" \
		--except=streams/single

anyt-falcon:
	ACTION_CABLE_ADAPTER=redis \
	bundle exec anyt --self-check --require="{lib/servers/falcon.rb,scripts/anyt/rails/*.rb}" \
		--rails-command="bundle exec ruby scripts/anyt/falcon.rb" \
		--except=features/server_restart,request/disconnection,features/channel_state

.PHONY: websocket-bench
