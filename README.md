# AtomicRedisCache

AtomicRedisCache is an overlay on top of the redis-rb library that allows you to
use Redis much like the Rails cache (ActiveSupport::Cache). It duplicates only
the .fetch() method, which reads from a key if present and valid, or else
evaluates the passed block and saves it as the new value at that key. The
foremost design goals apply mainly to webapps and are twofold:
- when cache expires, to avoid dogpile/thundering herd from multiple processes
recalculating by serving the cached value to all but one process, then updating
atomically when calculation by that process completes
- when calculation takes too long (i.e., due to db, network calls) and a
recently expired cached value is available, to fail fast with it and try
calculating again later (for a reaosnable # of retries)

## Installation

Add this line to your application's Gemfile:

    gem 'atomic_redis_cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install atomic_redis_cache

## Usage

Ensure that you set the value of `AtomicRedisCache.redis`. This can be either an
instance of redis-rb (or compatible), or a lambda/Proc evaluating to one. Ex.

```
AtomicRedisCache.redis = Redis.new(:host => '127.0.0.1', :port => 6379)
```

Then use it as you would Rails.cache:

```
>> v = AtomicRedisCache.fetch('key') { Faraday.get('example.com').status }
=> 200  # network call made
>> v = AtomicRedisCache.fetch('key') { }
=> 200  # value read from cache
```

There are a couple of configurable options can be set per fetch:
- `:expires_in` - expiry in seconds; defaults to a day
- `:race_condition_ttl` - time to lock down key for recalculation
- `:max_retries` - # of times to retry cache refresh before expiring

## Contributing

1. Fork it ( https://github.com/anujdas/atomic_redis_cache/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
