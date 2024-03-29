require 'simplecov'

if ENV['UPLOAD_COVERAGE_TO_CODACY']
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start do
  add_filter "/spec"
end

require 'webmock/rspec'
require 'rest-man'

require_relative './helpers'
require 'byebug' unless RUBY_PLATFORM == 'java'
require 'ruby-debug' if RUBY_PLATFORM == 'java'
require 'vcr'

VCR.configure do |config|
  config.default_cassette_options = { match_requests_on: %i[uri method] }
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.raise_errors_for_deprecations!

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # always run with ruby warnings enabled
  # TODO: figure out why this is so obscenely noisy (rspec bug?)
  # config.warnings = true

  # add helpers
  config.include Helpers, :include_helpers

  config.filter_run_when_matching :focus

  config.mock_with :rspec do |mocks|
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end
end

# always run with ruby warnings enabled (see above)
$VERBOSE = true
