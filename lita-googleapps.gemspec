Gem::Specification.new do |spec|
  spec.name = "lita-googleapps"
  spec.version = "1.0.0"
  spec.summary = "Fetch data from a google apps account"
  spec.description = "Adds some new commands for interacting with the google apps API"
  spec.license = "MIT"
  spec.files =  Dir.glob("{lib}/**/**/*")
  spec.extra_rdoc_files = %w{README.md MIT-LICENSE }
  spec.authors = ["James Healy"]
  spec.email   = ["james.healy@theconversation.edu.au"]
  spec.homepage = "http://github.com/conversation/lita-googleapps"
  spec.required_ruby_version = ">=1.9.3"
  spec.metadata = { "lita_plugin_type" => "handler" }

  spec.add_development_dependency("rake")
  spec.add_development_dependency("rspec", "~> 3.4")
  spec.add_development_dependency("pry")
  spec.add_development_dependency("rdoc")

  spec.add_dependency('lita-timing', '~>0.3')
  spec.add_dependency('lita')
  spec.add_dependency('google-api-client', '~>0.8.0')
end
