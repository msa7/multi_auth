class MultiAuth::User
  def initialize(@provider, @uid, @name, @raw_json)
  end

  getter provider : String
  getter uid : String
  getter name : String
  getter raw_json : String

  property email : String?
  property nickname : String?
  property first_name : String?
  property last_name : String?
  property location : String?
  property description : String?
  property image : String?
  property phone : String?
  property urls : Hash(String, String)?
  property access_token : OAuth2::AccessToken?
end
