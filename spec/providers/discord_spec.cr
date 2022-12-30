require "../spec_helper"

describe MultiAuth::Provider::Discord do
  it "generates authorize_uri" do
    uri = MultiAuth.make("discord", "/callback").authorize_uri
    uri.should start_with("https://discord.com/api/oauth2/authorize?client_id=discord_id&redirect_uri=%2Fcallback&response_type=code&scope=identify")
  end

  it "generates authorize_uri with state query param" do
    uri = MultiAuth.make("discord", "/callback").authorize_uri(state: "random_state_value")
    uri.should start_with("https://discord.com/api/oauth2/authorize?client_id=discord_id&redirect_uri=%2Fcallback&response_type=code&scope=identify&state=random_state_value")
  end

  it "fetch user" do
    WebMock.wrap do
      WebMock.stub(:post, "https://discord.com/api/v8/oauth2/token")
        .with(
          body: "client_id=discord_id&client_secret=discord_secret&redirect_uri=%2Fcallback&grant_type=authorization_code&code=123",
          headers: {
            "Accept"       => "application/json",
            "Content-type" => "application/x-www-form-urlencoded",
          }
        )
        .to_return(
          body: %({
            "access_token": "6qrZcUqja7812RVdnEKjpzOL4CvHBFG",
            "token_type": "Bearer",
            "expires_in": 604800,
            "refresh_token": "D43f5y0ahjqew82jZ4NViEr2YafMKhue",
            "scope": "identify"
          })
        )

      WebMock.stub(:get, "https://discord.com/api/v8/oauth2/@me")
        .to_return(body: File.read("spec/support/discord.json"))

      user = MultiAuth.make("discord", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.name.should eq("Discord")
    end
  end
end
