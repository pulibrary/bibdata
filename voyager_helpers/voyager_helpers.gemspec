# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'voyager_helpers'
  spec.version       = File.read(File.expand_path('../VERSION', __FILE__)).strip
  spec.authors       = ['Jon Stroop']
  spec.email         = ['jpstroop@gmail.com']
  spec.summary       = %q{Liberate MARC data from Voyager.}
  spec.homepage      = ''
  spec.license       = 'Simplified BSD'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'activesupport', '~> 4.1'
  spec.add_dependency 'marc', '~> 0.8.2'
  spec.add_dependency 'ruby-oci8', '~> 2.1.7'
  spec.add_dependency 'diffy', '~> 3.0.7'

end
