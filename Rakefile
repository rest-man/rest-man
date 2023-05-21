# load `rake build/install/release tasks'
require 'bundler/setup'
require_relative './lib/restman/version'

namespace :ruby do
  Bundler::GemHelper.install_tasks(:name => 'rest-man')
end

require "rspec/core/rake_task"

desc "Run all specs"
RSpec::Core::RakeTask.new('spec')

desc "Run unit specs"
RSpec::Core::RakeTask.new('spec:unit') do |t|
  t.pattern = 'spec/unit/*_spec.rb'
end

desc "Run integration specs"
RSpec::Core::RakeTask.new('spec:integration') do |t|
  t.pattern = 'spec/integration/*_spec.rb'
end

desc "Print specdocs"
RSpec::Core::RakeTask.new(:doc) do |t|
  t.rspec_opts = ["--format", "specdoc", "--dry-run"]
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Run all examples with RCov"
RSpec::Core::RakeTask.new('rcov') do |t|
  t.pattern = 'spec/*_spec.rb'
  t.rcov = true
  t.rcov_opts = ['--exclude', 'examples']
end

desc 'Regenerate authors file'
task :authors do
  Dir.chdir(File.dirname(__FILE__)) do
    File.open('AUTHORS', 'w') do |f|
      f.write <<-EOM
The Ruby REST Client would not be what it is today without the help of
the following kind souls:

      EOM
    end

    sh 'git shortlog -s | cut -f 2 >> AUTHORS'
  end
end

task :default do
  sh 'rake -T'
end

def alias_task(alias_task, original)
  desc "Alias for rake #{original}"
  task alias_task, Rake.application[original].arg_names => original
end
alias_task(:test, :spec)

############################

require 'rdoc/task'

Rake::RDocTask.new do |t|
  t.rdoc_dir = 'rdoc'
  t.title    = "rest-man, fetch RESTful resources effortlessly"
  t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
  t.options << '--charset' << 'utf-8'
  t.rdoc_files.include('README.md')
  t.rdoc_files.include('lib/*.rb')
end

############################

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end
alias_task(:lint, :rubocop)
