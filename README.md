# MultiAuth

[![Build Status](https://travis-ci.org/msa7/multi_auth.svg?branch=master)](https://travis-ci.org/msa7/multi_auth)

MultiAuth is a library that standardizes multi-provider authentication for web applications. Currently supported providers:

- Github.com
- Facebook.com
- Vk.com
- Google.com, [setup google](https://github.com/msa7/multi_auth/blob/master/setup.md#google)

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

## Contributing

1. Fork it ( https://github.com/msa7/multi_auth/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Sergey Makridenkov](https://github.com/msa7) - creator, maintainer
