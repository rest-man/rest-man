# -*- encoding: utf-8 -*-

require File.expand_path('../lib/restman/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'rest-man'
  s.version = RestMan::VERSION
  s.authors = ['Hopper Gee']
  s.description = 'A simple HTTP and REST client for Ruby, inspired by the Sinatra microframework style of specifying actions: get, put, post, delete.'
  s.license = 'MIT'
  s.email = 'hopper.gee@hey.com'
  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md']
  s.files = `git ls-files -z`.split("\0")
  s.test_files = `git ls-files -z spec/`.split("\0")
  s.bindir = "exe"
  s.executables = ['restman']

  s.homepage = 'https://github.com/rest-man/rest-man'
  s.summary = 'Simple HTTP and REST client for Ruby, inspired by microframework syntax for specifying actions.'

  s.add_development_dependency('webmock', '~> 3.0')
  s.add_development_dependency('rspec', '~> 3.0', '< 3.10')
  s.add_development_dependency('pry', '~> 0')
  s.add_development_dependency('pry-doc', '~> 0')
  s.add_development_dependency('rdoc', '>= 2.4.2', '< 7.0')
  s.add_development_dependency('rubocop', '~> 0.49')

  s.add_dependency('http-accept', '>= 1.7.0', '< 3.0')
  s.add_dependency('http-cookie', '>= 1.0.2', '< 2.0')
  s.add_dependency('mime-types', '>= 1.16', '< 4.0')
  s.add_dependency('netrc', '~> 0.8')

  s.required_ruby_version = '>= 2.0.0'

  case ENV['BUILD_PLATFORM'] || RUBY_PLATFORM
  when /(mingw32|mswin32)/
    # ffi is needed for RestMan::Windows::RootCerts
    s.add_dependency('ffi', '~> 1.9')
    s.platform = platform
  end
end