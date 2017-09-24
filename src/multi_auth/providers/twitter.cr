class MultiAuth::Provider::Twitter < MultiAuth::OAuthProvider
  def authorize_uri(scope = nil)
    request_token = consumer.get_request_token(oauth_callback)
    consumer.get_authorize_uri(request_token, oauth_callback)
  end

  def user(params : Hash(String, String))
    tw_user = fetch_tw_user(params["oauth_token"], params["oauth_verifier"])

    User.new(
      "twitter",
      tw_user.id,
      tw_user.name,
      tw_user.raw_json.to_s,
      tw_user.access_token.not_nil!
    ).tap do |user|
      user.email = tw_user.email
      user.nickname = tw_user.screen_name
      user.location = tw_user.location
      user.description = tw_user.description
      user.image = tw_user.profile_image_url
      if url = tw_user.url
        user.urls = {"twitter" => url}
      end
    end
  end

  private class TwUser
    property raw_json : String?
    property access_token : OAuth::AccessToken?

    JSON.mapping(
      id: {type: String, converter: String::RawConverter},
      name: String,
      screen_name: String,
      location: String?,
      description: String?,
      url: String?,
      profile_image_url: String?,
      email: String?
    )
  end

  private def fetch_tw_user(oauth_token, oauth_verifier)
    request_token = OAuth::RequestToken.new oauth_token, ""
    access_token = consumer.get_access_token(request_token, oauth_verifier)

    client = HTTP::Client.new("api.twitter.com", tls: true)
    access_token.authenticate(client, consumer_key, consumer_secret)

    raw_json = client.get("/1.1/account/verify_credentials.json?include_email=true").body

    TwUser.from_json(raw_json).tap do |user|
      user.access_token = access_token
      user.raw_json = raw_json
    end
  end

  private def consumer
    @consumer ||= OAuth::Consumer.new("api.twitter.com", consumer_key, consumer_secret)
  end
end
