source "https://rubygems.org"
ruby "3.3.6"

gem "rails",        "8.1.3"
gem "puma",         "8.0.1"
gem "pg",           "1.6.3"
gem "rack-cors",    "3.0.0"
gem "bcrypt",       "3.1.22"
gem "jwt",          "3.2.0"
gem "aws-sdk-s3",   "1.224.0"
gem "dotenv-rails", "3.2.0"
gem "kaminari",     "1.2.2"
gem "bootsnap",     "1.24.5", require: false
gem "rswag-api",    "2.17.0"
gem "rswag-ui",     "2.17.0"

gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug",                  platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails",            "8.0.4"
  gem "factory_bot_rails",      "6.5.1"
  gem "faker",                  "3.8.0"
  gem "rswag-specs",            "2.17.0"
  gem "brakeman",               "8.0.4",  require: false
  gem "bundler-audit",          "0.9.3",  require: false
  gem "rubocop-rails-omakase",  "1.1.0",  require: false
end

group :test do
  gem "shoulda-matchers", "7.0.1"
end
