require "../spec_helper"

describe MultiAuth::Provider::Google do
  it "generates authorize_uri" do
    uri = MultiAuth.make("google", "/callback").authorize_uri
    uri.should eq("https://accounts.google.com/o/oauth2/v2/auth?client_id=google_id&redirect_uri=%2Fcallback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.emails.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.phonenumbers.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.addresses.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fplus.login+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcontacts.readonly")
  end

  it "fetch user" do
    WebMock.wrap do
      WebMock.stub(:post, "https://www.googleapis.com/oauth2/v4/token")
             .with(
        body: "client_id=google_id&client_secret=google_secret&redirect_uri=%2Fcallback&grant_type=authorization_code&code=123",
        headers: {"Accept" => "application/json", "Content-Length" => "111", "Host" => "www.googleapis.com", "Content-type" => "application/x-www-form-urlencoded"}
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

      WebMock.stub(:get, "https://people.googleapis.com/v1/people/me?requestMask.includeField=person.addresses,person.biographies,person.bragging_rights,person.cover_photos,person.email_addresses,person.im_clients,person.interests,person.names,person.nicknames,person.phone_numbers,person.photos,person.urls")
             .to_return(body: File.read("spec/support/google.json"))

      user = MultiAuth.make("google", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.email.should eq("smkrbr@gmail.com")
    end
  end
end

context "facebook" do
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
end
