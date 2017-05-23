require 'pg'
require 'thread'
require 'logger'

module PgNotifier
  class Manager
    attr_accessor :logger, :db_config, :timeout

    def initialize(attrs = {})
      @logger = attrs.fetch :logger, Logger.new(STDOUT)
      @db_config = attrs.fetch :db_config , {}
      @timeout = attrs.fetch :timeout, 1

      @finish = false
      @mutex = Mutex.new
      @resource = ConditionVariable.new
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

      sig_read, sig_write = IO.pipe

      (%w[INT TERM HUP] & Signal.list.keys).each do |sig|
        trap sig do
          sig_write.puts(sig)
        end
      end

      Thread.new do
        channels.each do |channel|
          pg_result = connection.exec "LISTEN #{channel};"
        end

        @mutex.synchronize do
          until @finish do
            connection.wait_for_notify do |channel, pid, payload|
              logger.info "Notifying channel: #{channel}, pid: #{pid}, payload: #{payload}"

              subscriptions = subscriptions_by_channels.fetch channel, []
              subscriptions.each { |subscription| subscription.notify(channel, pid, payload) }
            end

            @resource.wait @mutex, timeout
          end
        end
      end

      while io = IO.select([sig_read])
        sig = io.first[0].gets.chomp
        handle_signal(sig)
      end
    end

    def handle_signal(sig)
      logger.debug "Got #{sig} signal"

      case sig
      when 'INT'
        shutdown
      when 'TERM'
        graceful_shutdown
      when 'HUP'
        graceful_shutdown
      end
    end

    def shutdown
      logger.info 'Shutting down'

      @finish = true
      close_connection

      exit(0)
    end

    def close_connection
      unless connection.finished?
        channels.each do |channel|
          connection.exec "UNLISTEN #{channel};"
        end

        connection.finish
      end
    end

    def graceful_shutdown
      logger.info 'Gracefully shutting down'

      @finish = true

      @mutex.synchronize do
        close_connection
        @resource.signal
      end

      exit(0)
    end
  end
end
