# frozen_string_literal: true

require "redis"
require "anycable-rails"

ActionCable.server.config.cable = {
  "adapter" => $benchmark_server == :anycable ? "any_cable" : "redis",
  "url" => ENV["REDIS_URL"]
}

class BenchmarkServer
  def self.run!
    require "anycable/cli"
    cli = AnyCable::CLI.new
    # We're already within the app context
    cli.define_singleton_method(:boot_app!) { }

    anycable_server_path = Rails.root.join("../bin/anycable-go")
    cli.run(["--server-command", "#{anycable_server_path} --host 0.0.0.0"])
  end
end
