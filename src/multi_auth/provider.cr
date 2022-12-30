abstract class MultiAuth::Provider
  getter redirect_uri : String
  getter key : String
  getter secret : String

  abstract def authorize_uri(scope = nil, state = nil)
  abstract def user(params : Hash(String, String))

  def initialize(@redirect_uri : String, @key : String, @secret : String)
  end
end
