require 'rspec'
require 'fakeredis/rspec'
require 'timecop'

require 'atomic_redis_cache'

RSpec.configure do |config|
  config.around(:each) do |example|
    Timecop.freeze(Time.now.utc, &example)
  end
end
