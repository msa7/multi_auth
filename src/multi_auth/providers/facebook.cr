class MultiAuth::Provider::Facebook < MultiAuth::Provider
  def authorize_uri(scope = nil, state = nil)
    scope ||= "email"
    client.get_authorize_uri(scope, state)
  end

  def user(params : Hash(String, String))
    fb_user = fetch_fb_user(params["code"])

    user = User.new(
      "facebook",
      fb_user.id,
      fb_user.name,
      fb_user.raw_json.as(String),
      fb_user.access_token.not_nil!
    )

    user.email = fb_user.email
    user.first_name = fb_user.first_name
    user.last_name = fb_user.last_name
    user.location = fb_user.location
    user.description = fb_user.about

    urls = {} of String => String
    urls["web"] = fb_user.website.as(String) if fb_user.website
    user.urls = urls unless urls.empty?

    user
  end

  private class FbUser
    include JSON::Serializable

    property raw_json : String?
    property access_token : OAuth2::AccessToken?
    property picture_url : String?

    property id : String
    property name : String
    property last_name : String?
    property first_name : String?
    property email : String?
    property location : String?
    property about : String?
    property website : String?
  end

  private def fetch_fb_user(code)
    access_token = token_client.get_access_token_using_authorization_code(code)
    api = HTTP::Client.new("graph.facebook.com", tls: true)
    access_token.authenticate(api)

    raw_json = api.get("/v2.9/me?fields=id,name,last_name,first_name,email,location,about,website").body

    fb_user = FbUser.from_json(raw_json)
    fb_user.access_token = access_token
    fb_user.raw_json = raw_json

    fb_user
  end

  private def client
    OAuth2::Client.new(
      "www.facebook.com",
      key,
      secret,
      redirect_uri: redirect_uri,
      authorize_uri: "/v2.9/dialog/oauth",
    )
  end

  private def token_client
    OAuth2::Client.new(
      "graph.facebook.com",
      key,
      secret,
      redirect_uri: redirect_uri,
      token_uri: "/v2.9/oauth/access_token",
      auth_scheme: :request_body
    )
  end
end
