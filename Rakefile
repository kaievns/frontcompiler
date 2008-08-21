require "rake"
require "rake/clean"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/testtask"
require "spec/rake/spectask"
require "fileutils"

def __DIR__
  File.dirname(__FILE__)
end

include FileUtils

NAME = "front_compiler"

require "lib/front_compiler"

def sudo
  ENV['FC_SUDO'] ||= "sudo"
  sudo = windows? ? "" : ENV['FC_SUDO']
end

def windows?
  (PLATFORM =~ /win32|cygwin/) rescue nil
end

def install_home
  ENV['GEM_HOME'] ? "-i #{ENV['GEM_HOME']}" : ""
end

##############################################################################
# Packaging & Installation
##############################################################################
CLEAN.include ["**/.*.sw?", "pkg", "lib/*.bundle", "*.gem", "doc/rdoc", ".config", "coverage", "cache"]

desc "Run the specs."
task :default => :specs

task :frontcompiler => [:clean, :rdoc, :package]

spec = Gem::Specification.new do |s|
  s.name         = NAME
  s.version      = FrontCompiler::VERSION
  s.platform     = Gem::Platform::RUBY
  s.author       = "Nikolay V. Nemshilov"
  s.email        = "n/a"
  s.homepage     = "n/a"
  s.summary      = "FrontCompiler is a simple collection of compactors for the JavaScript,
  CSS and HTML source code. It removes trailing whitespaces, comments and
  transformates the local variables to make the sourcecode shorter."
  s.bindir       = "bin"
  s.description  = s.summary
  s.executables  = %w(  )
  s.require_path = "lib"
  s.files        = %w( README Rakefile init.rb install.rb uninstall.rb ) + Dir["{docs,bin,spec,lib,examples,script}/**/*"]

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w( README )
  #s.rdoc_options     += RDOC_OPTS + ["--exclude", "^(app|uploads)"]

  # Dependencies
  # s.add_dependency "something"
  # Requirements
  s.required_ruby_version = ">= 1.8.4"
end

Rake::GemPackageTask.new(spec) do |package|
  package.gem_spec = spec
end

desc "Run :package and install the resulting .gem"
task :install => :package do
  sh %{#{sudo} gem install #{install_home} --local pkg/#{NAME}-#{FrontCompiler::VERSION}.gem --no-rdoc --no-ri}
end

desc "Run :clean and uninstall the .gem"
task :uninstall => :clean do
  sh %{#{sudo} gem uninstall #{NAME}}
end
