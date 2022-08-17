source "https://rubygems.org"

if !!File::ALT_SEPARATOR
  gemspec :name => 'simple-rest-client.windows'
else
  gemspec :name => 'simple-rest-client'
end

group :development, :test do
  gem 'vcr'
  gem 'rake'
  gem 'byebug'
end
