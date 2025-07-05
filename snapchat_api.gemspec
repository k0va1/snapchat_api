# frozen_string_literal: true

require_relative "lib/snapchat_api/version"

Gem::Specification.new do |spec|
  spec.name = "snapchat_api"
  spec.version = SnapchatApi::VERSION
  spec.authors = ["Alex Koval"]
  spec.email = ["al3xander.koval@gmail.com"]

  spec.summary = "Ruby wrapper for the Snapchat API"
  spec.description = "A comprehensive Ruby library for interacting with the Snapchat API"
  spec.homepage = "https://github.com/k0va1/snapchat_api"

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{bin,lib,exe}/**/*") + %w[LICENSE.txt README.md CHANGELOG.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "oauth2", "~> 2.0"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "faraday-follow_redirects", "~> 0.3"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "mime-types", "~> 3.1"
  spec.add_dependency "zeitwerk", "~> 2.6"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "1.49.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
end
