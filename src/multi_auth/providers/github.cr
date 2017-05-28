class MultiAuth::Provider::Github < MultiAuth::Provider
  def authorize_uri(scope = nil)
    client.get_authorize_uri("user:email")
  end

  def user(params : Hash(String, String))
    access_token = client.get_access_token_using_authorization_code(params["code"])
    api = HTTP::Client.new("api.github.com", tls: true)
    access_token.authenticate(api)
    response = api.get("/user")

    github_user = GithubUser.from_json(response.body)

    user = User.new("github", github_user.id, github_user.name, github_user.email, response.body)

    user.nickname = github_user.login
    user.location = github_user.location
    user.description = github_user.bio
    user.image = github_user.avatar_url
    user.urls = {"blog" => github_user.blog, "html" => github_user.html_url}
    user.access_token = access_token

    user
  end

  private class GithubUser
    JSON.mapping(
      id: {type: String, converter: String::RawConverter},
      name: String,
      email: String,
      login: String,
      location: String,
      bio: String,
      avatar_url: String,
      blog: String,
      html_url: String
    )
  end

  private def fetch_github_user(access_token)
  end

  private def client
    OAuth2::Client.new(
      "github.com",
      client_id,
      client_secret,
      authorize_uri: "/login/oauth/authorize",
      token_uri: "/login/oauth/access_token"
    )
  end
end
