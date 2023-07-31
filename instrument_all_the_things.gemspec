# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'instrument_all_the_things/version'

Gem::Specification.new do |spec|
  spec.name          = 'instrument_all_the_things'
  spec.version       = InstrumentAllTheThings::VERSION
  spec.authors       = ['Brian Malinconico']
  spec.email         = ['bmalinconico@terminus.com']

  spec.summary       = 'Make instrumentation with DataDog easy peasy'
  spec.description   = 'Wrappers to make instrumentation of methods easy and pleasant to read'
  spec.homepage      = 'https://github.com/GetTerminus/instrument-all-the-things'

  spec.metadata['allowed_push_host'] = 'https://www.rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/GetTerminus/instrument-all-the-things'
  # spec.metadata['changelog_uri'] = 'http://google.com'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|Gemfile.lock|vendor)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.add_dependency 'ddtrace', '~> 1.11'
  spec.add_dependency 'dogstatsd-ruby', '~> 5.5'

  spec.add_development_dependency 'benchmark-ips'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
