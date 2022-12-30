require "../spec_helper"

describe MultiAuth::Provider::Facebook do
  it "generates authorize_uri" do
    uri = MultiAuth.make("facebook", "/callback").authorize_uri
    uri.should eq("https://www.facebook.com/v2.9/dialog/oauth?client_id=facebook_id&redirect_uri=%2Fcallback&response_type=code&scope=email")
  end

  it "generates authorize_uri with state query param" do
    uri = MultiAuth.make("facebook", "/callback").authorize_uri(state: "random_state_value")
    uri.should eq("https://www.facebook.com/v2.9/dialog/oauth?client_id=facebook_id&redirect_uri=%2Fcallback&response_type=code&scope=email&state=random_state_value")
  end

  it "fetch user" do
    WebMock.wrap do
      WebMock
        .stub(:post, "https://graph.facebook.com/v2.9/oauth/access_token")
        .with(
          body: "client_id=facebook_id&client_secret=facebook_secret&redirect_uri=%2Fcallback&grant_type=authorization_code&code=123",
          headers: {"Accept" => "application/json", "Content-type" => "application/x-www-form-urlencoded"})
        .to_return(
          body: %({
                "access_token" : "1111",
                "token_type" : "Bearer",
                "expires_in" : 899,
                "refresh_token" : null,
                "scope" : "user"
              })
        )

      WebMock
        .stub(:get, "https://graph.facebook.com/v2.9/me?fields=id,name,last_name,first_name,email,location,about,website")
        .to_return(
          body: %({
              "name" : "Sergey",
              "id" : "3333"
            })
        )

      user = MultiAuth.make("facebook", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.name.should eq("Sergey")
      user.uid.should eq("3333")
    end
  end
end
