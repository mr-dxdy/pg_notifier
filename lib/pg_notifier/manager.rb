require 'pg'
require 'thread'
require 'logger'

module PgNotifier
  class Manager
    attr_accessor :logger, :db_config, :timeout

    def initialize(attrs = {})
      @logger = attrs.fetch :logger, Logger.new(STDOUT)
      @db_config = attrs.fetch :db_config , {}
      @timeout = attrs.fetch :timeout, 0.1

      @finish = false
      Thread.abort_on_exception = true

      @connection_mutex = Mutex.new
    end

    def notify(channel, options = {}, &block)
      subscriptions_by_channels[channel] ||= []
      subscriptions_by_channels[channel] << Subscription.new(channel, options, &block)
    end

    def subscriptions_by_channels
      @subscriptions_by_channels ||= {}
    end

    def channels
      subscriptions_by_channels.keys
    end

    def connection
      @connection ||= PG::Connection.open db_config
    end

    def run
      logger.info "Starting pg_notifier for #{channels.count} channels: [ #{channels.join(' ')} ]"

      Thread.new do
        channels.each do |channel|
          pg_result = @connection_mutex.synchronize { connection.exec "LISTEN #{channel};" }

          unless pg_result.result_status.eql? PG::PGRES_COMMAND_OK
            raise ChannelNotLaunched, "Channel ##{channel} not launched"
          end
        end

        until @finish do
          if notification = wait_notification()
            logger.info "Notifying channel: %s, pid: %s, payload: %s" % notification

            subscriptions = subscriptions_by_channels.fetch notification.first, []
            subscriptions.each { |subscription| subscription.notify(*notification) }
          end
        end
      end
    end

    def shutdown
      logger.info 'Shutting down'

      @finish = true

      @connection_mutex.synchronize do
        unless connection.finished?
          connection.async_exec "UNLISTEN *;"
          connection.finish
        end
      end

      exit(0)
    end

    private

    def wait_notification
      @connection_mutex.synchronize do
        connection.wait_for_notify(timeout) do |channel, pid, payload|
          return [channel, pid, payload]
        end
      end
    end
  end
end
