require "uuid"

class MultiAuth::Provider::Restream < MultiAuth::Provider
  def authorize_uri(scope = nil, state = nil)
    state ||= UUID.random.to_s
    uri = client.get_authorize_uri(scope, state)
  end

  def user(params : Hash(String, String))
    rs_user = fetch_rs_user(params["code"])

    user = User.new(
      "restream",
      rs_user.id,
      rs_user.username,
      rs_user.raw_json.as(String),
      rs_user.access_token.not_nil!
    )

    user.email = rs_user.email

    user
  end

  private class RestreamUser
    include JSON::Serializable

    property raw_json : String?
    property access_token : OAuth2::AccessToken?

    @[JSON::Field(converter: String::RawConverter)]
    property id : String

    property username : String?
    property email : String?
  end

  private def fetch_rs_user(code)
    access_token = client.get_access_token_using_authorization_code(code)

    api = HTTP::Client.new("api.restream.io", tls: true)
    access_token.authenticate(api)

    raw_json = api.get("/v2/user/profile").body
    rs_user = RestreamUser.from_json(raw_json)
    rs_user.access_token = access_token
    rs_user.raw_json = raw_json
    rs_user
  end

  private def client
    OAuth2::Client.new(
      "api.restream.io",
      key,
      secret,
      authorize_uri: "/login",
      token_uri: "/oauth/token",
      redirect_uri: redirect_uri,
      auth_scheme: :http_basic
    )
  end
end
