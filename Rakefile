require 'rake/testtask'
require 'rake/rdoctask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.title    = 'Executioner'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name     = "executioner"
    s.summary  = s.description = "Execute CLI utilities"
    s.email    = "eloy@fngtps.com"
    s.homepage = "http://fingertips.github.com"
    s.authors  = ["Eloy Duran"]
    s.add_runtime_dependency 'open4', '~> 1.1.0'
  end
rescue LoadError
end

begin
  require 'jewelry_portfolio/tasks'
  JewelryPortfolio::Tasks.new do |p|
    p.account = 'Fingertips'
  end
rescue LoadError
end
