require "../spec_helper"

describe MultiAuth::Provider::Vk do
  it "generates authorize_uri" do
    uri = MultiAuth.make("vk", "/callback").authorize_uri
    uri.should eq("https://oauth.vk.com/authorize?client_id=vk_id&redirect_uri=%2Fcallback&response_type=code&scope=email")
  end

  it "generates authorize_uri with state query param" do
    uri = MultiAuth.make("vk", "/callback").authorize_uri(state: "random_state_value")
    uri.should eq("https://oauth.vk.com/authorize?client_id=vk_id&redirect_uri=%2Fcallback&response_type=code&scope=email&state=random_state_value")
  end

  it "fetch user" do
    WebMock.wrap do
      WebMock
        .stub(:post, "https://oauth.vk.com/access_token")
        .with(
          body: "client_id=vk_id&client_secret=vk_secret&redirect_uri=%2Fcallback&grant_type=authorization_code&code=123",
          headers: {"Accept" => "application/json", "Content-Length" => "103", "Host" => "oauth.vk.com", "Content-type" => "application/x-www-form-urlencoded"})
        .to_return(
          body: %({
                "access_token" : "1111",
                "expires_in" : 899,
                "refresh_token" : null,
                "scope" : "email",
                "user_id" : "3333",
                "email" : "s@msa7.ru"
              })
        )

      WebMock
        .stub(:get, %(https://api.vk.com/method/users.get?fields=about,photo_max_orig,city,country,domain,contacts,site&user_id="3333"&v=5.52))
        .to_return(
          body: %({"response": [{
          "first_name" : "Sergey",
          "last_name" : "Makridenkov",
          "id" : 3333
        }]})
        )

      user = MultiAuth.make("vk", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.name.should eq("Makridenkov Sergey")
      user.uid.should eq("3333")
    end
  end
end
