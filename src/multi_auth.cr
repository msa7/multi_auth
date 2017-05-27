require "oauth2"
require "./multi_auth/**"

module MultiAuth
  @@configuration = Hash(String, Array(String)).new

  def self.init(provider, redirect_uri)
    MultiAuth::Engine.new(provider, redirect_uri)
  end

  def self.configuration
    @@configuration
  end

  def self.config(provider, client_id, client_secret)
    @@configuration[provider] = [client_id, client_secret]
  end
end
