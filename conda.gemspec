# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "conda"
  spec.version       = "0.1.2"
  spec.authors       = ["Isuru Fernando"]
  spec.email         = ["isuruf@gmail.com"]

  spec.summary       = "Ruby interface to Conda for binary packages"
  spec.homepage      = "https://github.com/isuruf/conda.rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }

end

