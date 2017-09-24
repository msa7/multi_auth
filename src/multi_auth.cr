require "oauth"
require "oauth2"
require "./multi_auth/**"

module MultiAuth
  @@configuration = Hash(String, Array(String)).new

  def self.make(provider, redirect_uri)
    MultiAuth::Engine.new(provider, redirect_uri)
  end

  def self.configuration
    @@configuration
  end

  def self.config(provider, key, secret)
    @@configuration[provider] = [key, secret]
  end
end
