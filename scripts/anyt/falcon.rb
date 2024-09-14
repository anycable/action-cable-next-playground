# frozen_string_literal: true

require "anyt/dummy/application"

require "anyt/tests"
require "anyt/remote_control"

require_relative "../../lib/servers/falcon"

# Ensure Async Redis is used at the server side
# (we switch to the regular Redis adapter at the AnyT CLI side, 'cause it's not Async-driven)
ActionCable.server.config.pubsub_adapter = "ActionCable::SubscriptionAdapter::AsyncRedis"

# Start remote control
Anyt::RemoteControl::Server.start(Anyt.config.remote_control_port)

# Load channels from tests
Anyt::Tests.load_all_tests

Rails.application.initialize!

Sync do
  websocket_endpoint = Async::HTTP::Endpoint.parse("http://127.0.0.1:9292/cable")

  action_cable_server = ActionCable.server
  # Replace the default executor with the Async executor
  action_cable_server.instance_variable_set(:@executor, ActionCable::Async::Executor.new)

  app = Falcon::Server.middleware(ActionCable::Async::App.new(server: action_cable_server))
  server = Falcon::Server.new(app, websocket_endpoint)
  server.run.wait
end
