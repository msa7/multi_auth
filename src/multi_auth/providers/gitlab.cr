class MultiAuth::Provider::Gitlab < MultiAuth::Provider
  def authorize_uri(scope = nil, state = nil)
    scope ||= ""
    client.get_authorize_uri(scope, state)
  end

  def user(params : Hash(String, String))
    gitlab_user = fetch_gitlab_user(params["code"])

    user = User.new(
      "gitlab",
      gitlab_user.id,
      gitlab_user.name,
      gitlab_user.raw_json.as(String),
      gitlab_user.access_token.not_nil!
    )

    user.email = gitlab_user.email
    user.nickname = gitlab_user.username
    user.location = gitlab_user.location
    user.description = gitlab_user.bio
    user.image = gitlab_user.avatar_url

    urls = {} of String => String
    urls["gitlab"] = gitlab_user.web_url.as(String) if gitlab_user.web_url

    user
  end

  private class GitlabUser
    include JSON::Serializable

    property raw_json : String?
    property access_token : OAuth2::AccessToken?

    @[JSON::Field(converter: String::RawConverter)]
    property id : String

    property name : String
    property username : String
    property avatar_url : String?
    property web_url : String?
    property bio : String?
    property location : String?
    property email : String?
  end

  private def fetch_gitlab_user(code)
    access_token = client.get_access_token_using_authorization_code(code)

    api = HTTP::Client.new(gitlab_url, tls: true)
    access_token.authenticate(api)

    raw_json = api.get("/api/v4/user").body
    gitlab_user = GitlabUser.from_json(raw_json)
    gitlab_user.access_token = access_token
    gitlab_user.raw_json = raw_json
    gitlab_user
  end

  private def gitlab_url
    ENV["OAUTH_GITLAB_URI"]? || "gitlab.com"
  end

  private def client
    OAuth2::Client.new(
      gitlab_url,
      key,
      secret,
      authorize_uri: "/oauth/authorize",
      token_uri: "/oauth/token",
      redirect_uri: redirect_uri,
      auth_scheme: :request_body
    )
  end
end
