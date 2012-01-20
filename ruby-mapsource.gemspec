# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mapsource/version"

Gem::Specification.new do |s|
  s.name        = "ruby-mapsource"
  s.version     = MapSource::VERSION
  s.authors     = ["Vitor Capela"]
  s.email       = ["dodecaphonic@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A Ruby library for reading MapSource/BaseCamp-created GDB files}
  s.description = %q{A Ruby library for reading MapSource/BaseCamp-created GDB files}

  s.rubyforge_project = "ruby-mapsource"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "minitest", "~> 2.10"
  s.add_development_dependency "mocha", "~> 0.10"
end
