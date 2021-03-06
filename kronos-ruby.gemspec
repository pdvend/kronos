# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'kronos/version'

Gem::Specification.new do |spec|
  spec.name          = 'kronos-ruby'
  pre_release        = ENV['SEMAPHORE'] && ENV['PRE_RELEASE']
  spec.version       = Kronos::VERSION + (pre_release ? ".alpha.#{ENV['SEMAPHORE_DEPLOY_NUMBER']}" : '')
  spec.authors       = ['Gabriel Teles']
  spec.email         = ['gabriel@pdvend.com.br']

  spec.summary       = 'Persistent cron jobs manager'
  spec.homepage      = 'https://github.com/pdvend/kronos-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby'
  spec.add_dependency 'chronic'
  spec.add_dependency 'mongoid'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'fasterer'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack'
  spec.add_development_dependency 'reek'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'webmock'
end
