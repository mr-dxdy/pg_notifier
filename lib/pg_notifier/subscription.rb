module PgNotifier
  class Subscription
    attr_reader :channel, :options, :block

    def initialize(channel, options, &block)
      @channel = channel
      @options = options
      @block = block
    end

    def notify(channel, pid, payload)
      block.call [channel, pid, payload]
    end
  end
end
