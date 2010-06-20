Gem::Specification.new do |s|
  s.name    = 'front-compiler'
  s.version = '1.1.0'
  s.date    = '2010-06-20'
  
  s.summary = "FrontCompiler is a Ruby based JavaScript/CSS/HTML compressor"
  s.description = "FrontCompiler is a Ruby based JavaScript/CSS/HTML compressor. It provides the basic JavaScript/CSS/HTML minifying feature. Plus it can create albeit packed JavaScript files, can inline CSS inside of JavaScript, works with DRYed CSS files and also can work as a RubyOnRails plugin."
  
  s.authors  = ['Nikolay Nemshilov']
  s.email    = 'nemshilov@gmail.com'
  s.homepage = 'http://github.com/MadRabbit/frontcompiler'
  
  s.files = Dir['lib/**/*'] + Dir['spec/**/*']
  s.files+= %w(
    README
    LICENSE
    CHANGELOG
    Rakefile
    init.rb
  )
  
  s.executables = ['frontcc']
end