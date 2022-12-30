class MultiAuth::Provider::Twitter < MultiAuth::Provider
  def authorize_uri(scope = nil, state = nil)
    request_token = consumer.get_request_token(redirect_uri)
    consumer.get_authorize_uri(request_token, redirect_uri)
  end

  def user(params : Hash(String, String))
    tw_user = fetch_tw_user(params["oauth_token"], params["oauth_verifier"])

    user = User.new(
      "twitter",
      tw_user.id,
      tw_user.name,
      tw_user.raw_json.to_s,
      tw_user.access_token.not_nil!
    )

    user.email = tw_user.email
    user.nickname = tw_user.screen_name
    user.location = tw_user.location
    user.description = tw_user.description
    user.image = tw_user.profile_image_url
    if url = tw_user.url
      user.urls = {"twitter" => url}
    end

    user
  end

  private class TwUser
    include JSON::Serializable

    property raw_json : String?
    property access_token : OAuth::AccessToken?

    @[JSON::Field(converter: String::RawConverter)]
    property id : String

    property name : String
    property screen_name : String
    property location : String?
    property description : String?
    property url : String?
    property profile_image_url : String?
    property email : String?
  end

  private def fetch_tw_user(oauth_token, oauth_verifier)
    request_token = OAuth::RequestToken.new(oauth_token, "")

    access_token = consumer.get_access_token(request_token, oauth_verifier)

    client = HTTP::Client.new("api.twitter.com", tls: true)
    access_token.authenticate(client, key, secret)

    raw_json = client.get("/1.1/account/verify_credentials.json?include_email=true").body

    TwUser.from_json(raw_json).tap do |user|
      user.access_token = access_token
      user.raw_json = raw_json
    end
  end

  private def consumer
    @consumer ||= OAuth::Consumer.new("api.twitter.com", key, secret)
  end
end
