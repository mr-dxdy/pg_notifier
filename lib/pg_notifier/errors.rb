module PgNotifier
  class PgNotifierError < StandardError; end
  class ChannelNotLaunched < PgNotifierError; end
end
