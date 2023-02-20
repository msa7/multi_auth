# MultiAuth

![Build Status](https://github.com/msa7/multi_auth/workflows/CI/badge.svg)

MultiAuth is a library that standardizes multi-provider authentication for web applications. Currently supported providers:

- Github.com
- Gitlab.com (or [own instance](https://github.com/msa7/multi_auth/blob/master/setup.md#gitlab))
- Facebook.com
- Vk.com
- Google.com, [setup google](https://github.com/msa7/multi_auth/blob/master/setup.md#google)
- Twitter.com
- Restream.io

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  multi_auth:
    github: msa7/multi_auth
```

## Usage

### MultiAuth public interface

```crystal
  require "multi_auth"

  MultiAuth.config("github", ENV['ID'], ENV['SECRET']) # configuration

  multi_auth = MultiAuth.make(provider, redirect_uri) # initialize engine
  multi_auth.authorize_uri  # URL to provider authentication dialog

  # on http callback, like /multi_auth/github/callback
  user = multi_auth.user(params) # get signed in user
```

MultiAuth build with no dependency, it can be used with any web framework. Information about signed in user described in User class here [src/multi_auth/user.cr](https://github.com/msa7/multi_auth/blob/master/src/multi_auth/user.cr). Supported providers [src/multi_auth/providers](https://github.com/msa7/multi_auth/blob/master/src/multi_auth/providers). I hope it easy to add new providers.

### [Kemal](http://kemalcr.com) integration example

```html
<a href="/multi_auth/github">Sign in with Github</a>
```

```crystal
MultiAuth.config("facebook", "facebookClientID", "facebookSecretKey")
MultiAuth.config("google", "googleClientID", "googleSecretKey")

def self.multi_auth(env)
  provider = env.params.url["provider"]
  redirect_uri = "#{Kemal.config.scheme}://#{env.request.host_with_port.as(String)}/multi_auth/#{provider}/callback"
  MultiAuth.make(provider, redirect_uri)
end

get "/multi_auth/:provider" do |env|
  env.redirect(multi_auth(env).authorize_uri)
end

get "/multi_auth/:provider/callback" do |env|
  user = multi_auth(env).user(env.params.query)
  p user.email
  user
end
```

### [Lucky](https://github.com/luckyframework/lucky) integration example

```crystal
# config/watch.yml
host: myapp.lvh.me
port: 5000

# config/multi_auth_handler.cr
require "multi_auth"

class MultiAuthHandler
  MultiAuth.config("facebook", "facebookClientID", "facebookSecretKey")
  MultiAuth.config("google", "googleClientID", "googleSecretKey")

  def self.authorize_uri(provider : String)
    MultiAuth.make(provider, "#{Lucky::RouteHelper.settings.base_uri}/oauth/#{provider}/callback").authorize_uri(scope: "email")
  end

  def self.user(provider : String, params : Enumerable({String, String}))
    MultiAuth.make(provider, "#{Lucky::RouteHelper.settings.base_uri}/oauth/#{provider}/callback").user(params)
  end
end

# src/actions/oauth/handler.cr
class OAuth::Handler < BrowserAction
  get "/oauth/:provider" do
    redirect to: MultiAuthHandler.authorize_uri(provider)
  end
end

# src/actions/oauth/handler/callback.cr
class OAuth::Handler::Callback < BrowserAction
  get "/oauth/:provider/callback" do
    user = MultiAuthHandler.user(provider, request.query_params)
    text user.email.to_s
  end
end
```

### [Amber](https://github.com/amberframework/amber) integration example

```crystal
# config/initializers/multi_auth.cr
require "multi_auth"

MultiAuth.config("facebook", "facebookClientID", "facebookSecretKey")
MultiAuth.config("google", "googleClientID", "googleSecretKey")

# config/routes.cr
routes :web do
  ...
  get "/multi_auth/:provider", MultiAuthController, :new
  get "/multi_auth/:provider/callback", MultiAuthController, :callback
end

# src/controllers/multi_auth_controller.cr
class MultiAuthController < ApplicationController
  def new
    redirect_to multi_auth.authorize_uri(scope: "email")
  end

  def callback
    multi_auth_user = multi_auth.user(request.query_params)

    if user = User.find_by email: multi_auth_user.email
      login user
    else
      user = User.create!(
        first_name: multi_auth_user.first_name,
        last_name: multi_auth_user.last_name,
        email: multi_auth_user.email
      )
      login user
    end

    redirect_to "/"
  end

  def login(user)
    context.session["user_id"] = user.id
  end

  def provider
    params[:provider]
  end

  def redirect_uri
    "#{Amber.settings.secrets["base_url"]}/multi_auth/#{provider}/callback"
  end

  def multi_auth
    MultiAuth.make(provider, redirect_uri)
  end
end
```

### [Marten](https://github.com/martenframework/marten) integration example

```crystal
# config/initializers/multi_auth.cr
# ----

require "multi_auth"

MultiAuth.config("github", "<github_client_id>", "<github_secret_key>")


# config/routes.cr
# ----

Marten.routes.draw do
  path "/oauth/<provider:string>", OAuthInitiateHandler, name: "oauth_initiate"
  path "/oauth/<provider:string>/callback", OAuthCallbackHandler, name: "oauth_callback"
end


# src/handlers/concerns/with_oauth.cr
# ----

module WithOAuth
  def multi_auth
    MultiAuth.make(provider, redirect_uri)
  end

  private def provider
    params["provider"].to_s
  end

  private def redirect_uri
    "#{request.scheme}://#{request.host}#{reverse("oauth_callback", provider: provider)}"
  end
end


# src/handlers/oauth_initiate_handler.cr
# ----

require "./concerns/**"

class OAuthInitiateHandler < Marten::Handler
  include WithOAuth

  def get
    redirect multi_auth.authorize_uri(scope: "email")
  end
end


# src/handlers/oauth_initiate_callback.cr
# ----

require "./concerns/**"

class OAuthCallbackHandler < Marten::Handler
  include WithOAuth

  def get
    user_params = Hash(String, String).new.tap do |params|
      request.query_params.each { |k, v| params[k] = v.last }
    end
    
    multi_auth_user = multi_auth.user(user_params)

    unless user = Auth::User.get(email: multi_auth_user.email)
      user = Auth::User.create!(email: multi_auth_user.email) do |new_user|
        new_user.set_unusable_password
      end
    end

    MartenAuth.sign_in(request, user)

    redirect "/"
  end
end
```

## Development

Install docker

Setup everythings

```
make setup
```

Run specs

```
make t
make t c=spec/providers/twitter_spec.cr
```

Run code linter

```
make l
```

## Contributors

- [Sergey Makridenkov](https://github.com/msa7) - creator, maintainer
- [Vitalii Elenhaupt](https://github.com/veelenga) - contributor
