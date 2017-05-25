require "pg_notifier/version"
require "pg_notifier/errors"
require "pg_notifier/subscription"
require "pg_notifier/manager"

module PgNotifier
  class << self
    def manager
      @manager ||= Manager.new
    end

    def run
      sig_read, sig_write = IO.pipe

      (%w[INT TERM HUP] & Signal.list.keys).each do |sig|
        trap sig do
          sig_write.puts(sig)
        end
      end

      manager.run

      while io = IO.select([sig_read])
        sig = io.first[0].gets.chomp

        manager.logger.debug "Got #{sig} signal"
        manager.shutdown if %w[INT TERM HUP].include? sig
      end
    end

    def notify(channel, options = {}, &block)
      manager.notify(channel, options, &block)
    end

    def configure(&block)
      manager.tap(&block)
    end
  end
end
