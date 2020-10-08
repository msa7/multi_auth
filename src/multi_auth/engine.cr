class MultiAuth::Engine
  def initialize(provider : String, redirect_uri : String)
    provider_class = case provider
                     when "google"   then Provider::Google
                     when "github"   then Provider::Github
                     when "gitlab"   then Provider::Gitlab
                     when "facebook" then Provider::Facebook
                     when "vk"       then Provider::Vk
                     when "twitter"  then Provider::Twitter
                     else
                       raise "Provider #{provider} not implemented"
                     end

    key, secret = MultiAuth.configuration[provider]
    @provider = provider_class.new(redirect_uri, key, secret)
  end

  getter provider : Provider

  def authorize_uri(scope = nil)
    provider.authorize_uri(scope)
  end

  def user(params : Enumerable({String, String})) : User
    provider.user(params.to_h)
  end
end
