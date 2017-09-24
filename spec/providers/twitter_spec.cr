require "../spec_helper"

describe MultiAuth::Provider::Twitter do
  request_token_params = {
    oauth_token:              "NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0",
    oauth_token_secret:       "veNRnAWe6inFuo8o2u8SLLZLjolYDmDP7SzL0YfYI",
    oauth_callback_confirmed: "true",
  }

  access_token_params = {
    oauth_token:        "7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4",
    oauth_token_secret: "PbKfYqSryyeKDWz4ebtY3o5ogNLG11WJuZBc9fQrQo",
  }

  verify_credentials_params = {
    id:                38895958,
    name:              "Sean Cook",
    screen_name:       "theSeanCook",
    location:          "San Francisco",
    url:               "http://twitter.com",
    description:       "I taught your phone that thing you like.  The Mobile Partner Engineer @Twitter.",
    profile_image_url: "http://a0.twimg.com/profile_images/1751506047/dead_sexy_normal.JPG",
    email:             "me@twitter.com",
  }

  describe "#authorize_uri" do
    it "generates authorize uri" do
      WebMock.stub(:post, "https://api.twitter.com/oauth/request_token")
             .to_return(body: HTTP::Params.encode request_token_params)
      uri = MultiAuth.make("twitter", "/callback").authorize_uri
      uri.should eq "https://api.twitter.com/oauth/authorize?oauth_token=NPcudxy0yU5T3tBzho7iCotZ3cnetKwcTIRlX0iwRl0&oauth_callback=%2Fcallback"
    end
  end

  describe "#fetch_tw_user" do
    it "successfully fetches user params" do
      WebMock.stub(:post, "https://api.twitter.com/oauth/access_token")
             .to_return(body: HTTP::Params.encode request_token_params)

      WebMock.stub(:get, "https://api.twitter.com/1.1/account/verify_credentials.json?include_email=true")
             .to_return(body: verify_credentials_params.to_json)

      user = MultiAuth.make("twitter", "/callback").user({"oauth_token" => "token", "oauth_verifier" => "verifier"})

      user.uid.should eq verify_credentials_params[:id].to_s
      user.email.should eq verify_credentials_params[:email]
      user.name.should eq verify_credentials_params[:name]
      user.nickname.should eq verify_credentials_params[:screen_name]
      user.location.should eq verify_credentials_params[:location]
      user.description.should eq verify_credentials_params[:description]
      user.image.should eq verify_credentials_params[:profile_image_url]
      user.urls.should eq({"twitter" => verify_credentials_params[:url]})

      user.provider.should eq "twitter"
      user.raw_json.should_not be_nil
      user.access_token.should_not be_nil
    end
  end
end
