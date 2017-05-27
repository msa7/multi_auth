class MultiAuth::Provider::Google < MultiAuth::Provider
  def authorize_uri(scope = nil)
    oauth2_client = OAuth2::Client.new(
      "accounts.google.com",
      client_id,
      client_secret,
      authorize_uri: "/o/oauth2/v2/auth",
      redirect_uri: redirect_uri
    )

    oauth2_client.get_authorize_uri("profile email openid")
  end

  def user(params : Hash(String, String))
    access_token = get_access_token(params["code"])
    p "access_token #{access_token}"
    nil

    # code=4/Eyr6K3sxsLPiN28Z9SPkAqdJRSJhOcV5N8TKu8qBAvc
    # &authuser=0
    # &session_state=e55994130393dbe0607b7c1dbc62fd716e806b75..487e
    # &prompt=consent

    # access_token = OAuth2::AccessToken::Bearer.new(params_hash["code"], 172_800)

    # client = HTTP::Client.new("accounts.google.com", tls: true)

    # # Prepare it for using OAuth2 authentication
    # access_token.authenticate(client)

    # # Execute requests as usual: they will be authenticated
    # client.get("/some_path")

    # User.new(params)
  end

  # def raw_info
  # @raw_info ||= access_token.get('https://www.googleapis.com/plus/v1/people/me/openIdConnect').parsed
  # end

  private def get_access_token(authorization_code)
    oauth2_client = OAuth2::Client.new(
      "www.googleapis.com",
      client_id,
      client_secret,
      token_uri: "/oauth2/v4/token",
      redirect_uri: redirect_uri
    )

    oauth2_client.get_access_token_using_authorization_code(authorization_code)
  end
end
