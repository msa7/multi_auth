require "../spec_helper"

describe MultiAuth::Provider::Gitlab do
  it "generates authorize_uri" do
    uri = MultiAuth.make("gitlab", "/callback").authorize_uri
    uri.should eq("https://gitlab.com/oauth/authorize?client_id=gitlab_id&redirect_uri=%2Fcallback&response_type=code&scope=")
  end

  it "generates authorize_uri with state query param" do
    uri = MultiAuth.make("gitlab", "/callback").authorize_uri(state: "random_state_value")
    uri.should eq("https://gitlab.com/oauth/authorize?client_id=gitlab_id&redirect_uri=%2Fcallback&response_type=code&scope=&state=random_state_value")
  end

  it "fetch user" do
    WebMock.wrap do
      WebMock.stub(:post, "https://gitlab.com/oauth/token")
        .with(
          body: "client_id=gitlab_id&client_secret=gitlab_secret&redirect_uri=%2Fcallback&grant_type=authorization_code&code=123",
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

      WebMock.stub(:get, "https://gitlab.com/api/v4/user")
        .to_return(body: File.read("spec/support/gitlab.json"))

      user = MultiAuth.make("gitlab", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.email.should eq("jade.kharats@gmail.com")
    end
  end
end
