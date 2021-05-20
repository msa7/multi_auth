require "oauth"
require "oauth2"
require "./multi_auth/**"

module MultiAuth
  @@configuration = Hash(String, Tuple(String, String, String?)).new

  def self.make(provider, redirect_uri, scope = nil)
    MultiAuth::Engine.new(provider, redirect_uri, scope)
  end

  def self.configuration
    @@configuration
  end

  def self.config(provider, key, secret, scope = nil)
    @@configuration[provider] = {key, secret, scope}
  end
end
