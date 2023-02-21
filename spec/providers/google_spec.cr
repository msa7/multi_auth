require "../spec_helper"

describe MultiAuth::Provider::Google do
  it "generates authorize_uri" do
    uri = MultiAuth.make("google", "/callback").authorize_uri
    uri.should eq("https://accounts.google.com/o/oauth2/v2/auth?client_id=google_id&redirect_uri=%2Fcallback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.emails.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.phonenumbers.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.addresses.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fplus.login+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcontacts.readonly")
  end

  it "generates authorize_uri with state query param" do
    uri = MultiAuth.make("google", "/callback").authorize_uri(state: "random_state_value")
    uri.should eq("https://accounts.google.com/o/oauth2/v2/auth?client_id=google_id&redirect_uri=%2Fcallback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.emails.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.phonenumbers.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuser.addresses.read+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fplus.login+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcontacts.readonly&state=random_state_value")
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

      WebMock.stub(:get, "https://people.googleapis.com/v1/people/me?personFields=addresses,biographies,bragging_rights,cover_photos,email_addresses,im_clients,interests,names,nicknames,phone_numbers,photos,urls")
        .to_return(body: File.read("spec/support/google.json"))

      user = MultiAuth.make("google", "/callback").user({"code" => "123"}).as(MultiAuth::User)

      user.email.should eq("smkrbr@gmail.com")
    end
  end

  context "when API disabled" do
    it "shows error" do
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

        WebMock.stub(:get, "https://people.googleapis.com/v1/people/me?personFields=addresses,biographies,bragging_rights,cover_photos,email_addresses,im_clients,interests,names,nicknames,phone_numbers,photos,urls")
          .to_return(body: File.read("spec/support/google_api_disabled.json"))

        expect_raises(Exception) do
          MultiAuth.make("google", "/callback").user({"code" => "123"})
        end
      end
    end
  end

  context "when the user has no names set on their account" do
    it "still returns a user" do
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

        WebMock.stub(:get, "https://people.googleapis.com/v1/people/me?personFields=addresses,biographies,bragging_rights,cover_photos,email_addresses,im_clients,interests,names,nicknames,phone_numbers,photos,urls")
          .to_return(body: File.read("spec/support/google_without_names.json"))

        user = MultiAuth.make("google", "/callback").user({"code" => "123"}).as(MultiAuth::User)

        user.email.should eq("smkrbr@gmail.com")
      end
    end
  end
end
