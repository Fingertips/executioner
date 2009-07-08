require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name     = "executioner"
    s.summary  = s.description = "Execute CLI utilities"
    s.email    = "eloy@fngtps.com"
    s.homepage = "http://fingertips.github.com"
    s.authors  = ["Eloy Duran"]
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