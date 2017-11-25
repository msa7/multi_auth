# MultiAuth

[![Build Status](https://travis-ci.org/msa7/multi_auth.svg?branch=master)](https://travis-ci.org/msa7/multi_auth)

MultiAuth is a library that standardizes multi-provider authentication for web applications. Currently supported providers:

- Github.com
- Facebook.com
- Vk.com
- Google.com, [setup google](https://github.com/msa7/multi_auth/blob/master/setup.md#google)
- Twitter.com

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

### Kemal integration example

```html
<a href="/multi_auth/github">Sign in with Github</a>
```

```crystal
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
end
```

### Lucky integration example

Instructions for using with [Lucky Framework](https://github.com/luckyframework/lucky).

First, set up MultiAuth in a config file:


```crystal
# config/app.cr
class App
  URL = "http://localhost:3000"
end
```

```crystal
# config/multi_auth_handler.cr
require "multi_auth"

class MultiAuthHandler
  ALLOWED_PROVIDERS = %w[facebook google]
  MultiAuth.config("facebook", "facebookClientID", "facebookSecretKey")
  MultiAuth.config("google", "googleClientID", "googleSecretKey")

  def self.authorize_uri(provider : String)
    MultiAuth.make(provider, "#{App::URL}/oauth/#{provider}/callback").authorize_uri
  end

  def self.user(provider : String, params : Enumerable({String, String}))
    if ALLOWED_PROVIDERS.includes?(provider)
      MultiAuth.make(provider, "#{App::URL}/oauth/#{provider}/callback")
    else
      raise "provider '#{provider}' not found."
    end
  end
end
```

Then, create an action to begin the oauth flow.

```crystal
# src/actions/oauth/handler.cr
class OAuth::Handler < BrowserAction
  get "/oauth/:provider" do
    if ALLOWED_PROVIDERS.includes?(provider)
      redirect to: MultiAuthHandler.authorize_uri(provider)
    else
      json({ error: "provider #{provider} not supported" }, status: 400)
    end
  end
end
```

And the provider callback.

```crystal
# src/actions/oauth/handler/callback.cr
class OAuth::Handler::Callback < BrowserAction
  get "/oauth/:provider/callback" do
    if ALLOWED_PROVIDERS.includes?(provider)
      user = MultiAuthHandler.user(provider, request.query_params)
      render_text user.email
    else
      json({ error: "provider #{provider} not supported" }, status: 400)
    end
  end
end
```

## Contributing

1. Fork it ( https://github.com/msa7/multi_auth/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Sergey Makridenkov](https://github.com/msa7) - creator, maintainer
- [Vitalii Elenhaupt](https://github.com/veelenga) - contributor
