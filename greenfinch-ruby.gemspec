require File.join(File.dirname(__FILE__), 'lib/greenfinch-ruby/version.rb')

spec = Gem::Specification.new do |spec|
  spec.name = 'greenfinch-ruby'
  spec.version = Greenfinch::VERSION
  spec.files = Dir.glob(`git ls-files`.split("\n"))
  spec.require_paths = ['lib']
  spec.summary = 'Official Greenfinch tracking library for ruby'
  spec.description = 'The official Greenfinch tracking library for ruby'
  spec.authors = [ 'KoreaCreditData' ]
  spec.email = 'terry@kcd.co.kr'
  spec.homepage = 'https://github.com/koreacreditdata/greenfinch-ruby'
  spec.license = 'Apache-2.0'

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'activesupport', '~> 4.0'
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 1.18'
end
