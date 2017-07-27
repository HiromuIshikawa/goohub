require 'redis'
module Goohub
  module DataStore
    class RedisStore < Base
      def initialize(options = {})
        @redis = Redis.new(options)
      end

      def load(key)
        @redis.get(key)
      end

      def store(key, value)
        @redis.set(key, value)
      end

      def delete(key)
        @redis.del(key)
      end

      def keys
        self.glob('*')
      end

      def glob(pattern)
        @redis.keys(pattern)
      end
    end # class RedisStore
  end # module DataStore
end # module Goohub
