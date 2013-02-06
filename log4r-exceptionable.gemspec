# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "log4r-exceptionable/version"

Gem::Specification.new do |s|
  s.name        = "log4r-exceptionable"
  s.version     = Log4rExceptionable::VERSION
  s.authors     = ["Matt Conway"]
  s.email       = ["matt@conwaysplace.com"]
  s.homepage    = ""
  s.summary     = %q{Failure handlers for rack and resque that log failures using log4r}
  s.description = %q{Failure handlers for rack and resque that log failures using log4r.  It is expected that these logs will get sent elsewhere (e.g. graylog) by using log4r outputters (e.g. log4r-gelf)}

  s.rubyforge_project = "log4r-exceptionable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
  s.add_development_dependency("awesome_print")
  
  s.add_development_dependency("rack-test")
  s.add_development_dependency("resque")
  s.add_development_dependency("sidekiq")
  s.add_dependency("log4r")
end
