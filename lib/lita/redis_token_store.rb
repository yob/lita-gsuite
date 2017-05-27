module Lita
  # This is a local, simplified copy of Google::Auth::Stores::RedisTokenStore.
  #
  # After a user authenticates via Google OAuth we need to store a copy of their
  # tokens in redis so we can call the Google APIs on their behalf. The googleauth
  # library can store the tokens using any class that conforms to the
  # Google::Auth::TokenStore contract.
  #
  # The RedisTokenStore provided by the googleauth gem works well enough, but it
  # assumes that the provided redis object is a plain Redis instance. Lita wraps
  # the Redis instance in a Redis::Namespace, so we need this custom store implementation.
  #
  # A nice side-effect is that we can rely on the Redis::Namespace instance to prefix keys
  # for us which removes some complexity from the class.
  #
  class RedisTokenStore
    KEY_PREFIX = 'g-user-token:'

    # Create a new store with the supplied redis client.
    #
    def initialize(redis)
      @redis = redis
    end

    def load(id)
      key = key_for(id)
      @redis.get(key)
    end

    def store(id, token)
      key = key_for(id)
      @redis.set(key, token)
    end

    def delete(id)
      key = key_for(id)
      @redis.del(key)
    end

    private

    # Generate a redis key from a token ID
    #
    def key_for(id)
      KEY_PREFIX + id
    end
  end
end
