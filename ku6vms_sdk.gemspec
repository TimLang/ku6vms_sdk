# -*- encoding: utf-8 -*-

# Load version requiring the canonical "sndacs/version", otherwise Ruby will think
# is a different file and complaint about a double declaration of Sndacs::VERSION.
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "grandcloud"

Gem::Specification.new do |s|
  s.name        = "ku6vms_sdk"
  s.version     = GrandCloud::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tim Lang"]
  s.email       = ["langyong135@gmail.complaint"]
  s.homepage    = "https://github.com/TimLang/ku6vms_sdk"
  s.summary     = "Library for accessing Ku6vms"
  s.description = "ku6vms library provides access to SNDA ku6vms."

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "em-http-request", "~> 1.0.0"
  s.add_development_dependency "bundler", ">= 1.0.0"
  #s.add_development_dependency "rspec", "~> 2.0"
  #s.add_development_dependency "test-unit", ">= 2.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = "lib"
end

