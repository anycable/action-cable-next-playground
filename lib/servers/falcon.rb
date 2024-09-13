# frozen_string_literal: true

# TODO: This is an old version from here: https://github.com/anycable/anycable/blob/a0c48aeffe7b57f8abcf49ec244e2129f7424c97/benchmarks/rails/bento#L113
# Requires upgrade for Action Cable 8
class AsyncApp
  def call(req)
		Async::WebSocket::Adapters::HTTP.open(req) do |connection|
      env = {url: "/cable"}

      connected = AnyCable.rpc_handler.handle(
        :connect,
        AnyCable::ConnectionRequest.new(env: env)
      ).then do |response|
        handle_response(connection, response)

        if response.status != :SUCCESS
          connection.close
          next false
        end

        true
      end

      next unless connected

      loop do
        msg = connection.read
        cmd = Protocol::WebSocket::JSONMessage.wrap(msg)&.to_h

        next unless cmd

        identifier = cmd[:identifier]
        command = cmd[:command]

        case command
        when "subscribe"
          AnyCable.rpc_handler.handle(
            :command,
            AnyCable::CommandMessage.new(
              command:,
              identifier:,
              connection_identifiers: "{}",
              env:
            )
          ).then do |response|
            handle_response(connection, response, identifier)
          end
        when "message"
          AnyCable.rpc_handler.handle(
            :command,
            AnyCable::CommandMessage.new(
              command:,
              identifier:,
              connection_identifiers: "{}",
              data: cmd[:data],
              env:
            )
          ).then do |response|
            handle_response(connection, response, identifier)
          end
        end
      end
    rescue EOFError
		end
	end

  private

  def handle_response(connection, response, identifier = nil)
    response.transmissions&.each do |msg|
      connection.write(msg)
    end
    connection.flush

    # Command response
    if identifier
      writer = proc do |msg|
        msg = {identifier: identifier, message: JSON.parse(msg)}.to_json
        connection.write(msg)
        connetion.flush
      end

      response.streams&.each do |stream|
        ActionCable.server.pubsub.subscribe(stream, writer)
      end
    end
  end
end

class BenchmarkServer
  def self.run!
    require "async/websocket"
    require "async/websocket/adapters/http"
    require 'protocol/websocket/json_message'

    require "falcon/command"
    require "falcon/command/serve"

    # Patch Action Cable subscriber to be async-aware
    require "async/semaphore"
    ActionCable::SubscriptionAdapter::SubscriberMap.prepend(Module.new do
      def initialize(...)
        super
        @semaphore = Async::Semaphore.new(1024)
      end

      def broadcast(channel, message)
        list = @sync.synchronize do
          return if !@subscribers.key?(channel)
          @subscribers[channel].dup
        end

        Async do
          list.each do |subscriber|
            @semaphore.async do
              invoke_callback(subscriber, message)
            end
          end
        end
      end
    end)

    cmd = Falcon::Command::Serve.new(["-p", "8080", "-b", "tcp://0.0.0.0", "--#{ENV.fetch("FALCON_MODE", "forked")}"])
    cmd.define_singleton_method(:load_app) { AsyncApp.new }
    cmd.call
  end
end
