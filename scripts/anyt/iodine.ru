# frozen_string_literal: true

require "anyt/dummy/application"

require "anyt/tests"
require "anyt/remote_control"

require_relative "../../lib/servers/iodine"

# Start remote control
Anyt::RemoteControl::Server.start(Anyt.config.remote_control_port)

# Load channels from tests
Anyt::Tests.load_all_tests

Rails.application.initialize!

app = Rack::Builder.new do
  map "/cable" do
    use ActionCable::Iodine::Middleware
    run(proc { |_| [404, {"Content-Type" => "text/plain"}, ["Not here"]] })
  end
end

run app
