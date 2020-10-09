require "spec"
require "webmock"
require "../src/multi_auth"

MultiAuth.config("google", "google_id", "google_secret")
MultiAuth.config("github", "github_id", "github_secret")
MultiAuth.config("gitlab", "gitlab_id", "gitlab_secret")
MultiAuth.config("facebook", "facebook_id", "facebook_secret")
MultiAuth.config("vk", "vk_id", "vk_secret")
MultiAuth.config("twitter", "twitter_consumer_key", "twitter_consumer_secret")
