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
  s.add_development_dependency('rubocop', '~> 1.50.2')

  s.add_dependency('http-accept', '>= 1.7.0', '< 3.0')
  s.add_dependency('http-cookie', '>= 1.0.2', '< 2.0')
  s.add_dependency('mime-types', '>= 3.0', '< 4.0')
  s.add_dependency('netrc', '~> 0.8')
  s.add_dependency('active_method', '~> 1.3')

  s.required_ruby_version = '>= 2.6.0'
end
