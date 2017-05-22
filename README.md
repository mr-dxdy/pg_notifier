# PgNotifier

Process notifies about postgresql notifications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_notifier'
```

## Quickstart

Create notifiers.rb:

``` ruby
require 'pg_notifier'

module PgNotifier
  configure do |notifier|
    notifier.logger = Logger.new('/var/log/pg_notifier.log')
    notifier.timeout = 1
    notifier.db_config = {
      host: 'localhost',
      port: 5432,
      dbname: database_production,
      user: 'postgres',
      password: 'postgres'
    }
  end

  notify 'created_user' do |channel, pid, payload|
    puts "#{channel} #{pid} #{payload}"
  end
end
```
Run it with the pg_notifier executable:

``` bash
$ pg_notifier notifiers.rb
```

If you need to load your entire environment for your jobs, simply add:

``` bash
require 'pg_notifier'

require './config/boot'
require './config/environment'
```
