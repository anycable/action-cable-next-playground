# frozen_string_literal: true

require "async"
require "async/http/endpoint"
require "async/websocket/adapters/rack"
require "async/redis"

require "falcon"

module ActionCable
  module SubscriptionAdapter
    # A PoC of Async-powered Redis subscription adapter.
    # TODO: handle Redis connection failures.
    #
    # Why not regular Redis adapter? It spawns a thread to listen for events and
    # perform broadcasts from it—that doesn't work with the Async executor ('no current task').
    class AsyncRedis < Base
      prepend ChannelPrefix

      private attr_reader :subscriber

      def initialize(*)
        super
        @endpoint = ::Async::Redis.local_endpoint
        @mutex = Mutex.new
      end

      def broadcast(channel, payload)
        publisher.publish(channel, payload)
      end

      def subscribe(channel, callback, success_callback = nil)
        subscriber.add_subscriber(channel, callback, success_callback)
      end

      def unsubscribe(channel, callback)
        subscriber.remove_subscriber(channel, callback)
      end

      def shutdown
        subscriber.shutdown if @subscriber
      end

      private

      def publisher
        @publisher || @mutex.synchronize { @publisher ||= ::Async::Redis::Client.new(@endpoint) }
      end

      def subscriber
        @subscriber || @mutex.synchronize { @subscriber ||= Subscriber.new(@endpoint, executor) }
      end

      class Subscriber < SubscriberMap::Async
        private attr_reader :client, :ctx, :task

        def initialize(endpoint, executor)
          super(executor)
          @client = ::Async::Redis::Client.new(endpoint)
          @ctx = new_subscribe_context
          @task = new_subscribe_task(ctx)
        end

        def add_channel(channel, on_success)
          ctx.subscribe(channel)
          on_success&.call
        end

        def remove_channel(channel)
          ctx.unsubscribe(channel)
        end

        def shutdown
          task&.stop
        end

        private

        def new_subscribe_context
          client.subscribe("_action_cable_internal")
        end

        def new_subscribe_task(ctx)
          Async do
            while event = ctx.listen
              if event.first == "message"
                broadcast(event[1], event[2])
              end
            end
          end
        end
      end
    end
  end

  module Async
    class Executor
      class Timer < Data.define(:task)
        def shutdown = task.stop
      end

      private attr_reader :semaphore

      def initialize(max_size: 1024)
        @semaphore = ::Async::Semaphore.new(max_size)
      end

      def post(task = nil, &block)
        task ||= block
        semaphore.async(&task)
      end

      def timer(interval, &block)
        task = Async do
          loop do
            sleep(interval)
            block.call
          end
        end

        Timer.new(task)
      end

      def shutdown = @executor.shutdown
    end

    class Socket
      #== Action Cable socket interface ==
      attr_reader :env, :logger, :protocol
      private attr_reader :conn, :coder, :server

      delegate :worker_pool, :logger, to: :server

      def initialize(env, conn, server, coder: ActiveSupport::JSON)
        @env = env
        @coder = coder
        @server = server
        @conn = conn
      end

      def request
        # Copied from ActionCable::Server::Socket#request
        @request ||= begin
          environment = Rails.application.env_config.merge(env) if defined?(Rails.application) && Rails.application
          ActionDispatch::Request.new(environment || env)
        end
      end

      def transmit(data)
        conn.write(coder.encode(data))
        conn.flush
      rescue IOError, Errno::EPIPE => e
        logger.debug "Failed to write to the socket: #{e.message}"
      end

      def close
        conn.close
      end

      def perform_work(receiver, ...)
        Async do
          receiver.send(...)
        rescue Exception => e
          logger.error "There was an exception - #{e.class}(#{e.message})"
          logger.error e.backtrace.join("\n")

          receiver.handle_exception if receiver.respond_to?(:handle_exception)
        end
      end
    end

    class App
      private attr_reader :server, :semaphore

      def initialize(server: ::ActionCable.server, max_size: 1024)
        @server = server
        @semaphore = ::Async::Semaphore.new(max_size)
      end

      def call(env)
        ::Async::WebSocket::Adapters::Rack.open(env, protocols: ::ActionCable::INTERNAL[:protocols]) do |conn|
          coder = ActiveSupport::JSON
          logger = server.logger
          # A _Socket interface for Action Cable connection
          socket = Socket.new(env, conn, server)
          # Action Cable connection instance
          connection = server.config.connection_class.call.new(server, socket)

          # Handshake
          connection.handle_open

          server.setup_heartbeat_timer
          server.add_connection(connection)

          # Main loop
          # FIXME: closed socket errors are not triggered for some connections,
          # so we cannot detect the disconnect and call #handle_close
          # (e.g., when running AnyT tests; that's why we had to skip some)
          while (msg = conn.read)
            semaphore.async do
              logger.debug "[Async WebSocket] incoming message: #{msg.to_str}"

              connection.handle_incoming(coder.decode(msg.to_str))
            end
          end
        rescue EOFError, Errno::ECONNRESET
          logger.debug "[Async WebSocket] connection closed"
          if connection
            server.remove_connection(connection)
            semaphore.async do
              connection.handle_close
            end
          end
        rescue Exception => e
          logger.error "There was an exception - #{e.class}(#{e.message})"
        end or [200, [], ["Websocket only."]]
      end
    end
  end
end

# That's a workaround for making it possible to run this code in Async and non-Async environment (e.g., AnyT)
unless ENV["ACTION_CABLE_ADAPTER"] == "redis"
  ActionCable.server.config.pubsub_adapter = "ActionCable::SubscriptionAdapter::AsyncRedis"
end

class BenchmarkServer
  def self.run!
    Sync do
    	websocket_endpoint = Async::HTTP::Endpoint.parse("http://127.0.0.1:8080/cable")

      action_cable_server = ActionCable.server
      # Replace the default executor with the Async executor
      action_cable_server.instance_variable_set(:@executor, ActionCable::Async::Executor.new)

    	app = Falcon::Server.middleware(ActionCable::Async::App.new(server: action_cable_server))
    	server = Falcon::Server.new(app, websocket_endpoint)
    	server.run.wait
    end
  end
end
