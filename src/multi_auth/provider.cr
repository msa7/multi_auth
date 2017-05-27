  abstract class MultiAuth::Provider
    getter redirect_uri : String
    getter client_id : String
    getter client_secret : String

    def initialize(@redirect_uri : String, @client_id : String, @client_secret : String)
    end

    abstract def authorize_uri(scope = nil)
    abstract def user(params : Hash(String, String))
  end
