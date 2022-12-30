require "../spec_helper"

describe MultiAuth::Provider::Restream do
  it "generates authorize_uri" do
    uri = MultiAuth.make("restream", "/callback").authorize_uri
    uri.should start_with("https://api.restream.io/login?client_id=restream_id&redirect_uri=%2Fcallback&response_type=code&state=")
  end

  it "generates authorize_uri with state query param" do
    uri = MultiAuth.make("restream", "/callback").authorize_uri(state: "random_state_value")
    uri.should start_with("https://api.restream.io/login?client_id=restream_id&redirect_uri=%2Fcallback&response_type=code&state=random_state_value")
  end

  it "fetch user" do
    WebMock.wrap do
      WebMock.stub(:post, "https://api.restream.io/oauth/token")
        .with(
          body: "redirect_uri=%2Fcallback&grant_type=authorization_code&code=123",
          headers: {
            "Accept"         => "application/json",
            "Content-type"   => "application/x-www-form-urlencoded",
            "Authorization"  => "Basic cmVzdHJlYW1faWQ6cmVzdHJlYW1fc2VjcmV0",
            "Content-Length" => "63",
            "Host"           => "api.restream.io",
          }
        )
        .to_return(
          body: %({
            "access_token": "7e61c8a5e2f99404730c511de6580412e618da35",
            "token_type" : "Bearer",
            "expires_in": 3600,
            "refresh_token": "0e633c3343a2df84b1526f4c2e6993ff17e05cab",
            "scopeJson" : [
              "profile.default.read",
              "stream.default.read"
            ]
          })
        )

      WebMock.stub(:get, "https://api.restream.io/v2/user/profile")
        .to_return(body: File.read("spec/support/restream.json"))

      user = MultiAuth.make("restream", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.email.should eq("xxxxx@email.test")
    end
  end
end
