abstract class MultiAuth::Provider
  getter redirect_uri : String
  getter key : String
  getter secret : String
  getter scope : String?

  abstract def authorize_uri
  abstract def user(params : Hash(String, String))

  def initialize(@redirect_uri : String, @key : String, @secret : String, scope = nil)
    @scope = build_scope(scope)
  end

  protected abstract def build_scope(scope)
end
