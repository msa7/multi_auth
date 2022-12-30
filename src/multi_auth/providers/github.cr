class MultiAuth::Provider::Github < MultiAuth::Provider
  def authorize_uri(scope = nil, state = nil)
    scope ||= "user:email"
    client.get_authorize_uri(scope, state)
  end

  def user(params : Hash(String, String))
    gh_user = fetch_gh_user(params["code"])

    user = User.new(
      "github",
      gh_user.id,
      gh_user.name,
      gh_user.raw_json.as(String),
      gh_user.access_token.not_nil!
    )

    user.email = gh_user.email
    user.nickname = gh_user.login
    user.location = gh_user.location
    user.description = gh_user.bio
    user.image = gh_user.avatar_url

    urls = {} of String => String
    urls["blog"] = gh_user.blog.as(String) if gh_user.blog
    urls["github"] = gh_user.html_url.as(String) if gh_user.html_url
    user.urls = urls unless urls.empty?

    user
  end

  private class GhUser
    include JSON::Serializable

    property raw_json : String?
    property access_token : OAuth2::AccessToken?

    @[JSON::Field(converter: String::RawConverter)]
    property id : String

    property name : String?
    property email : String?
    property login : String
    property location : String?
    property bio : String?
    property avatar_url : String?
    property blog : String?
    property html_url : String?
  end

  private def fetch_gh_user(code)
    access_token = client.get_access_token_using_authorization_code(code)

    api = HTTP::Client.new("api.github.com", tls: true)
    access_token.authenticate(api)

    raw_json = api.get("/user").body
    gh_user = GhUser.from_json(raw_json)
    gh_user.access_token = access_token
    gh_user.raw_json = raw_json
    gh_user
  end

  private def client
    OAuth2::Client.new(
      "github.com",
      key,
      secret,
      authorize_uri: "/login/oauth/authorize",
      token_uri: "/login/oauth/access_token",
      auth_scheme: :request_body
    )
  end
end
