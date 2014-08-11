require 'spec_helper'

describe AtomicRedisCache, :order => :random do
  subject         { AtomicRedisCache }

  let(:redis)     { Redis.new }

  let(:key)       { 'key' }
  let(:val)       { {:a => 1} }
  let(:m_val)     { Marshal.dump(val) }
  let(:timer_key) { "timer:#{key}" }
  let(:now)       { Time.now.to_i }

  before { subject.redis = redis }

  describe '.redis=' do
    it 'accepts a Redis instance' do
      subject.redis = Redis.new
      expect { subject.read(key) }.to_not raise_error
    end
    it 'accepts a lambda evaluating to a Redis instance' do
      subject.redis = lambda { Redis.new }
      expect { subject.read(key) }.to_not raise_error
    end
  end

  describe '.fetch' do
    it 'requires .redis to be set' do
      subject.redis = nil
      expect { subject.fetch(key) { val } }.to raise_error(ArgumentError)
    end

    it 'serializes complex objects for storage' do
      subject.fetch(key) { val }
      expect(redis.get(key)).to eq(m_val)
    end

    it 'de-serializes objects on retrieval' do
      redis.mset(key, m_val, timer_key, now)
      expect(subject.fetch(key)).to eq(val)
    end

    it 'returns nil if a key does not exist' do
      expect(subject.read(key)).to be_nil
    end
  end

  describe '.read' do
    it 'requires .redis to be set' do
      subject.redis = nil
      expect { subject.read(key) }.to raise_error(ArgumentError)
    end

    it 'de-serializes objects on retrieval' do
      redis.mset(key, m_val, timer_key, now)
      expect(subject.read(key)).to eq(val)
    end

    it 'returns nil if a key does not exist' do
      expect(subject.read(key)).to be_nil
    end

    it 'returns nil if a key is present but expired' do
      redis.mset(key, m_val, timer_key, now)
      expect(subject.read(key)).to eq(val)
      Timecop.travel(now + 1) do
        expect(subject.read(key)).to be_nil
      end
    end
  end

  describe '.write' do
    it 'requires .redis to be set' do
      subject.redis = nil
      expect { subject.write(key, val) }.to raise_error(ArgumentError)
    end

    it 'serializes complex objects for storage' do
      subject.write(key, val)
      expect(redis.get(key)).to eq(m_val)
    end
  end

  describe '.delete' do
    it 'requires .redis to be set' do
      subject.redis = nil
      expect { subject.delete(key) }.to raise_error(ArgumentError)
    end

    it 'returns false if a key does not exist' do
      expect(subject.delete(key)).to be_falsey
    end

    it 'returns true if a key exists' do
      redis.mset(key, m_val, timer_key, now)
      expect(subject.delete(key)).to be_truthy
    end

    it 'deletes both the key and timer' do
      redis.mset(key, m_val, timer_key, now)
      subject.delete(key)
      expect(redis.get(key)).to be_nil
      expect(redis.get(timer_key)).to be_nil
    end
  end
end
