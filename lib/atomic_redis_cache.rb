require 'atomic_redis_cache/version'

module AtomicRedisCache
  DEFAULT_EXPIRATION = 60*60*24  # 86400 seconds in a day
  DEFAULT_RACE_TTL = 30          # seconds to acquire new value
  MAX_RETRIES = 3                # recalc attempts before expiring cache

  class << self
    attr_writer :redis

    # Fetch from cache with fallback, just like ActiveSupport::Cache.
    # The main differences are in the edge cases around expiration.
    # - when cache expires, we avoid dogpile/thundering herd
    #   from multiple processes recalculating at once
    # - when calculation takes too long (i.e., due to network traffic)
    #   we return the previously cached value for several attempts
    # Options:
    # :expires_in - expiry in seconds; defaults to a day
    # :race_condition_ttl - time to lock value for recalculation
    # :max_retries - # of times to retry cache refresh before expiring
    def fetch(key, opts={}, &blk)
      expires_in = opts[:expires_in] || DEFAULT_EXPIRATION
      race_ttl   = opts[:race_condition_ttl] || DEFAULT_RACE_TTL
      retries    = opts[:max_retries] || MAX_RETRIES

      now        = Time.now.to_i
      ttl        = expires_in + retries * race_ttl
      t_key      = "timer:#{key}"

      if val = redis.get(key)              # cache hit
        if redis.get(t_key).to_i < now     # expired entry or dne
          redis.set t_key, now + race_ttl  # block other callers for recalc duration
          begin
            Timeout.timeout(race_ttl) do   # if recalc exceeds race_ttl, abort
              val = Marshal.dump(blk.call) # determine new value
              redis.multi do               # atomically cache + mark as valid
                redis.setex key, ttl, val
                redis.set t_key, now + expires_in
              end
            end
          rescue Timeout::Error => e       # eval timed out, use cached val
          end
        end
      else                                 # cache miss
        val = Marshal.dump(blk.call)       # determine new value
        redis.multi do                     # atomically cache + mark as valid
          redis.setex key, ttl, val
          redis.set t_key, now + expires_in
        end
      end

      Marshal.load(val)
    end

    def delete(key)
      redis.del(key) == 1
    end

    def redis
      raise 'AtomicRedisCache.redis must be set before use.' unless @redis
      @redis.respond_to?(:call) ? @redis.call : @redis
    end
    private :redis
  end
end
