source "https://rubygems.org"

if !!File::ALT_SEPARATOR
  gemspec :name => 'rest-client.windows'
else
  gemspec :name => 'rest-client'
end

group :development, :test do
  gem 'vcr'
  gem 'rake'
  gem 'byebug'
end
