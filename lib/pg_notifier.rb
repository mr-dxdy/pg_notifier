require "pg_notifier/version"
require "pg_notifier/subscription"
require "pg_notifier/manager"

module PgNotifier
  class << self
    def manager
      @manager ||= Manager.new
    end

    def run
      manager.run
    end

    def notify(channel, options = {}, &block)
      manager.notify(channel, options, &block)
    end

    def configure(&block)
      manager.tap(&block)
    end
  end
end
