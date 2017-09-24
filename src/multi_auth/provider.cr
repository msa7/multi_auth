module MultiAuth
  abstract class Provider
    abstract def authorize_uri(scope = nil)
    abstract def user(params : Hash(String, String))
  end

  abstract class OAuthProvider < Provider
    getter oauth_callback : String
    getter consumer_key : String
    getter consumer_secret : String

    def initialize(@oauth_callback : String, @consumer_key : String, @consumer_secret : String)
    end
  end

  abstract class OAuth2Provider < Provider
    getter redirect_uri : String
    getter client_id : String
    getter client_secret : String

    def initialize(@redirect_uri : String, @client_id : String, @client_secret : String)
    end
  end
end
