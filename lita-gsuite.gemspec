Gem::Specification.new do |spec|
  spec.name = "lita-gsuite"
  spec.version = "1.0.0"
  spec.summary = "Monitor activity and data in a gsuite account"
  spec.description = "Adds commands to lita for monitoring gsuite account activity and flagging potential issues"
  spec.license = "MIT"
  spec.files =  Dir.glob("{lib}/**/**/*")
  spec.extra_rdoc_files = %w{README.md MIT-LICENSE }
  spec.authors = ["James Healy"]
  spec.email   = ["james.healy@theconversation.edu.au"]
  spec.homepage = "http://github.com/yob/lita-gsuite"
  spec.required_ruby_version = ">=1.9.3"
  spec.metadata = { "lita_plugin_type" => "handler" }

  spec.add_development_dependency("rake")
  spec.add_development_dependency("rspec", "~> 3.4")
  spec.add_development_dependency("pry")
  spec.add_development_dependency("rdoc")

  spec.add_dependency('lita-timing', '~>0.3')
  spec.add_dependency('lita')
  spec.add_dependency('google-api-client', '~>0.9')
end
