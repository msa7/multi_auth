# src/multi_auth/providers/apple.cr
require "../../multi_auth"
require "jwt"
require "openssl"
require "oauth2"

class MultiAuth::Provider::Apple < MultiAuth::Provider
  # Apple requires these in initializer
  property team_id : String
  property key_id : String
  property private_key : OpenSSL::PKey::EC
  property private_key_path : String?

  def initialize(key : String, secret : String, redirect_uri : String, 
                 team_id : String, key_id : String, private_key_path : String)
    super("apple", key, secret, redirect_uri)
    @team_id = team_id
    @key_id = key_id
    @private_key_path = private_key_path
    @private_key = OpenSSL::PKey::EC.new(File.read(private_key_path))
  end

  # For testing with in-memory key
  def initialize(key : String, secret : String, redirect_uri : String,
                 team_id : String, key_id : String, private_key : OpenSSL::PKey::EC)
    super("apple", key, secret, redirect_uri)
    @team_id = team_id
    @key_id = key_id
    @private_key = private_key
  end

  # Generate JWT client secret (Apple's special requirement)
  private def generate_client_secret : String
    now = Time.utc.to_unix
    
    headers = {
      "alg" => "ES256",
      "kid" => @key_id
    }
    
    claims = {
      "iss" => @team_id,
      "iat" => now,
      "exp" => now + 15780000,  # 6 months max
      "aud" => "https://appleid.apple.com",
      "sub" => @key  # client_id
    }
    
    JWT.encode(claims, @private_key, JWT::Algorithm::ES256, headers)
  end

  # Override authorize_uri - Apple uses standard OAuth2 flow
  def authorize_uri(scope = nil, state = nil)
    scope ||= "name email"
    client.get_authorize_uri(scope, state)
  end

  # Main user fetching method (same pattern as GitHub)
  def user(params : Hash(String, String))
    # Exchange code for tokens using JWT client_secret
    access_token = fetch_apple_tokens(params["code"])
    
    # Decode ID token to get user info
    id_token = access_token.not_nil!.extra["id_token"].as(String)
    apple_user = fetch_apple_user(id_token)
    
    # Build standardized MultiAuth::User object
    user = User.new(
      "apple",
      apple_user.sub,  # Apple's unique user ID
      apple_user.email,
      apple_user.raw_json.as(String),
      access_token.not_nil!.access_token
    )
    
    user.email = apple_user.email
    user.first_name = apple_user.first_name
    user.last_name = apple_user.last_name
    user.name = "#{apple_user.first_name} #{apple_user.last_name}".strip
    user.email_verified = apple_user.email_verified
    
    # Apple provides a user ID that's stable across your apps
    user.nickname = apple_user.sub
    
    user
  end

  # Apple user info from ID token (JWT)
  private class AppleUser
    include JSON::Serializable
    
    property raw_json : String?
    
    # Standard OpenID Connect claims
    property sub : String        # unique user ID
    property email : String?
    property email_verified : Bool?
    
    # Apple specific - name only comes on first login
    property name : JSON::Any?
    
    # Helper to extract first/last name from the 'name' object
    def first_name : String?
      return unless name
      name["firstName"]?.try &.as_s
    end
    
    def last_name : String?
      return unless name
      name["lastName"]?.try &.as_s
    end
  end

  private def fetch_apple_user(id_token : String) : AppleUser
    # ID token is a JWT - decode the payload
    payload, _ = JWT.decode(id_token, verify: false)
    
    apple_user = AppleUser.from_json(payload.to_json)
    apple_user.raw_json = payload.to_json
    
    # Apple only sends name on first login, so it might be nil
    # We need to handle that case gracefully
    apple_user
  rescue ex
    raise OAuth2::Error.new("Failed to decode Apple ID token: #{ex.message}")
  end

  private def fetch_apple_tokens(code : String) : OAuth2::AccessToken
    # Client for token exchange (using JWT as client_secret)
    token_client = OAuth2::Client.new(
      "appleid.apple.com",
      @key,                    # client_id
      generate_client_secret,  # JWT as client_secret
      authorize_uri: "/auth/authorize",
      token_uri: "/auth/token"
    )
    
    # Exchange authorization code for tokens
    token_client.get_access_token_using_authorization_code(code, redirect_uri: @redirect_uri)
  rescue ex
    raise OAuth2::Error.new("Apple token exchange failed: #{ex.message}")
  end

  # Custom client for authorize_uri (Apple's endpoints)
  private def client
    OAuth2::Client.new(
      "appleid.apple.com",
      @key,
      generate_client_secret,  # JWT as client_secret
      authorize_uri: "/auth/authorize",
      token_uri: "/auth/token",
      auth_scheme: :request_body  # Apple requires POST with form-encoded body
    )
  end
end

# Register the provider
MultiAuth::Providers.register("apple", MultiAuth::Provider::Apple)
