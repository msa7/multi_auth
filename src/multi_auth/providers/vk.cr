class MultiAuth::Provider::Vk < MultiAuth::Provider
  def authorize_uri(scope = nil)
    @scope = "email"
    client.get_authorize_uri(@scope)
  end

  def user(params : Hash(String, String))
    vk_user = fetch_vk_user(params["code"])

    user = User.new(
      "vk",
      vk_user.id,
      vk_user.name,
      vk_user.raw_json.not_nil!,
      vk_user.access_token.not_nil!
    )

    user.email = vk_user.email
    user.first_name = vk_user.first_name
    user.last_name = vk_user.last_name
    user.nickname = vk_user.domain
    user.description = vk_user.about
    user.image = vk_user.photo_max_orig
    user.phone = vk_user.mobile_phone || vk_user.home_phone

    location = [] of String
    location << vk_user.city.not_nil!.title if vk_user.city
    location << vk_user.country.not_nil!.title if vk_user.country
    user.location = location.join(", ") unless location.empty?

    urls = {} of String => String
    urls["web"] = vk_user.site.not_nil! if vk_user.site
    user.urls = urls unless urls.empty?

    user
  end

  class VkTitle
    JSON.mapping(
      title: String
    )
  end

  class VkUser
    property raw_json : String?
    property access_token : OAuth2::AccessToken?
    property email : String?
    property id : String?

    def name
      "#{last_name} #{first_name}"
    end

    JSON.mapping(
      id: {type: String, converter: String::RawConverter},
      last_name: String?,
      first_name: String?,
      site: String?,
      city: VkTitle?,
      country: VkTitle?,
      domain: String?,
      about: String?,
      photo_max_orig: String?,
      mobile_phone: String?,
      home_phone: String?
    )
  end

  class VkResponse
    JSON.mapping(
      response: Array(VkUser),
    )
  end

  private def fetch_vk_user(code)
    access_token = client.get_access_token_using_authorization_code(code)

    api = HTTP::Client.new("api.vk.com", tls: true)
    access_token.authenticate(api)

    user_id = access_token.extra.not_nil!["user_id"]
    user_email = access_token.extra.not_nil!["email"]

    fields = "about,photo_max_orig,city,country,domain,contacts,site"
    raw_json = api.get("/method/users.get?fields=#{fields}&user_id=#{user_id}&v=5.52").body

    vk_user = VkResponse.from_json(raw_json).response.first
    vk_user.email = user_email
    vk_user.access_token = access_token
    vk_user.raw_json = raw_json

    vk_user
  end

  private def client
    OAuth2::Client.new(
      "oauth.vk.com",
      client_id,
      client_secret,
      redirect_uri: redirect_uri,
      authorize_uri: "/authorize",
      token_uri: "/access_token"
    )
  end
end
