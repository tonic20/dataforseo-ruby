require_relative "lib/dataforseo/version"

Gem::Specification.new do |spec|
  spec.name = "dataforseo-ruby"
  spec.version = DataForSeo::VERSION
  spec.authors = ["Anton Kopylov"]
  spec.email = ["anton@tonic20.com"]

  spec.summary = "Unofficial Ruby client for the DataForSEO API"
  spec.description = "A dependency-free Ruby client for DataForSEO Live endpoints: " \
                     "envelope checking, typed errors, batching and a fake transport for tests."
  spec.homepage = "https://www.kopylov.net/blog/dataforseo-ruby-a-client-that-respects-the-bill.html"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tonic20/dataforseo-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/tonic20/dataforseo-ruby/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
