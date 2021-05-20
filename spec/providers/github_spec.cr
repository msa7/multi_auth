require "../spec_helper"

describe MultiAuth::Provider::Github do
  it "generates authorize_uri" do
    uri = MultiAuth.make("github", "/callback").authorize_uri
    uri.should eq("https://github.com/login/oauth/authorize?client_id=github_id&redirect_uri=&response_type=code&scope=user%3Aemail")
  end

  it "fetch user" do
    WebMock.wrap do
      WebMock.stub(:post, "https://github.com/login/oauth/access_token")
        .with(
          body: "client_id=github_id&client_secret=github_secret&redirect_uri=&grant_type=authorization_code&code=123",
          headers: {"Accept" => "application/json", "Content-type" => "application/x-www-form-urlencoded"}
        )
        .to_return(
          body: %({
            "access_token" : "1111",
            "token_type" : "Bearer",
            "expires_in" : 899,
            "refresh_token" : null,
            "scope" : "user"
          })
        )

      WebMock.stub(:get, "https://api.github.com/user")
        .to_return(body: File.read("spec/support/github.json"))

      user = MultiAuth.make("github", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.email.should eq("hi@msa7.ru")
    end
  end

  it "fetch user public email when scope user:email", focus: true do
    [
      {"email" => "public@msa.im", "primary" => true, "verified" => true, "visibility" => "public"},
      {"email" => "private@msa.im", "primary" => false, "verified" => true, "visibility" => null},
    ]

    WebMock.allow_net_connect = true
    MultiAuth.config("github", ENV["GITHUB_KEY"], ENV["GITHUB_SECRET"])

    multi_auth = MultiAuth.make("github", "https://webhook.site/4ac71fc0-592f-449a-a4b0-af63679f952c")

    p multi_auth.authorize_uri

    user = multi_auth.user({"code" => "bccef469b279f106920d"}).as(MultiAuth::User)
    p user
    # user.email.should eq("hi@msa7.ru")
  end
end
