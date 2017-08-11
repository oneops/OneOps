$:.unshift File.expand_path("../lib", __FILE__)

require 'version'

Gem::Specification.new do |s|
  s.name        = 'oneops-admin'
  s.version     = '1.0.0'
  s.license     = 'Apache-2.0'
  s.author      = 'OneOps'
  s.email       = 'support@oneops.com'
  s.homepage    = 'http://www.oneops.com'
  s.summary     = 'OneOps Admin'
  s.description = 'OneOps circuit and inductor commands.'
  s.executables = %w(circuit inductor i)

  s.platform         = Gem::Platform::RUBY
  s.extra_rdoc_files = %w()

  s.add_dependency "thor", '= 0.19.1'
  s.add_dependency "activesupport", '= 4.1.10'
  s.add_dependency "activeresource", '= 4.0.0'
  s.add_dependency "activemodel", '= 4.1.10'
  s.add_dependency "ffi", '= 1.9.10'
  s.add_dependency "fog", '= 1.37.0'
  s.add_dependency "aws-s3", '= 0.6.3'
  s.add_dependency "chef", '= 12.0.0'
  s.add_dependency "ohai", '= 8.0.1'
  s.add_dependency "mime-types", '= 1.25.1'
  s.add_dependency "mixlib-shellout", '= 2.2.7'
  s.add_dependency "net-ssh", '= 2.6.5'
  s.add_dependency "net-scp", '= 1.1.2'
  s.add_dependency "net-ldap", '= 0.6.1'
  s.add_dependency "json", '= 1.8.3'
  s.add_dependency "nokogiri", '= 1.6.8'
  s.add_dependency "kramdown", '= 1.9.0'
  s.add_dependency "route53", '= 0.3.2'
  s.add_dependency "fog-azure-rm", '= 0.2.7'
  s.add_dependency "fog-vsphere", '= 1.3.0'
  s.add_dependency "crack", '= 0.4.3'
  s.add_dependency "rack", '= 1.6.4'
  s.add_dependency "rake", '= 10.1.1'
  s.add_dependency "fog-aliyun", '= 0.1.0'
  s.bindir       = 'bin'
  s.require_path = 'lib'
  s.files        = %w() + ["oneops-admin.gemspec"] + ["Gemfile"] + Dir.glob(".chef/**/*") + Dir.glob("lib/**/*") + ["target/inductor-#{Inductor::VERSION}.jar"] + Dir.glob('bin/**/*')
end