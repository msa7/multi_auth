class MultiAuth::Engine
  def initialize(provider : String, redirect_uri : String, scope : String? = nil)
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
    @provider = provider_class.new(redirect_uri, key, secret, scope)
  end

  getter provider : Provider

  def authorize_uri
    provider.authorize_uri
  end

  def user(params : Enumerable({String, String})) : User
    provider.user(params.to_h)
  end
end
