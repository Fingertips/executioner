require File.expand_path('../test_helper', __FILE__)

class AClassThatUsesSubshells
  include Executioner
  executable :sh
  executable :doesnotexistforsure
  executable 'executable-with-dash'
  executable :with_path, :path => '/path/to/executable'
end

describe "Executioner, the module" do
  it "should assign an optional logger" do
    begin
      logger = Object.new
      Executioner.logger = logger
      Executioner.logger.should.be logger
    ensure
      Executioner.logger = nil
    end
  end
end

describe "Executioner, instance methods" do
  before do
    @object = AClassThatUsesSubshells.new
  end
  
  it "should raise a Executioner::ProcessError if a command could not be executed" do
    proc = lambda { @object.send(:execute, "/bin/sh -M") }
    
    proc.should.raise Executioner::ProcessError
    
    begin
      proc.call
    rescue Executioner::ProcessError => error
      error.message.should =~ %r%Command: "/bin/sh -M"%
      error.message.should =~ %r%Output: "/bin/sh: -M: invalid option%
    end
  end
  
  it "should be able to switch stdout and stderr, for instance for ffmpeg" do
    lambda { @object.send(:execute, "/bin/sh -M", :switch_stdout_and_stderr => true) }.should.not.raise Executioner::ProcessError
  end
  
  it "should help concat arguments" do
    @object.send(:concat_args, [[:foo, 'foo'], [:bar, 'bar']]).should == "-foo foo -bar bar"
  end
  
  it "should queue one command" do
    @object.send(:queue, 'ls')
    @object.send(:queued_commands).should == 'ls'
  end
  
  it "should queue multiple commands" do
    @object.send(:queue, 'ls')
    @object.send(:queue, 'cat')
    @object.send(:queued_commands).should == 'ls && cat'
  end
  
  it "should execute queued commands" do
    @object.send(:queue, 'ls')
    @object.send(:queue, 'ls')
    @object.expects(:execute).with(@object.send(:queued_commands), {})
    @object.send(:execute_queued)
    @object.send(:queued_commands).should == ''
  end
end

describe "Executioner, class methods" do
  before do
    @object = AClassThatUsesSubshells.new
  end
  
  it "should define an instance method for the specified binary that's needed" do
    AClassThatUsesSubshells.instance_methods.should.include 'sh'
  end
  
  it "should define an instance method which calls #execute with the correct path to the executable" do
    @object.expects(:execute).with('/bin/sh with some args', {:switch_stdout_and_stderr => false})
    @object.sh 'with some args'
  end
  
  it "should define an instance method for an executable with dashes replaced by underscores" do
    @object.should.respond_to :executable_with_dash
  end
  
  it "should be possible to switch stdin and stderr" do
    AClassThatUsesSubshells.class_eval { executable(:sh, {:switch_stdout_and_stderr => true}) }
    @object.expects(:execute).with('/bin/sh with some args', {:switch_stdout_and_stderr => true})
    @object.sh 'with some args'
  end
  
  it "should be possible to use the queue by default" do
    AClassThatUsesSubshells.class_eval { executable(:sh, {:use_queue => true}) }
    @object.expects(:execute).with('/bin/sh arg1 && /bin/sh arg2', {})
    @object.sh 'arg1'
    @object.sh 'arg2'
    @object.execute_queued
  end
  
  it "should be possible to specify the path to the executable" do
    @object.expects(:execute).with { |command, options| command == "/path/to/executable arg1" }
    @object.with_path 'arg1'
  end
  
  it "should be possible to find an executable" do
    File.stubs(:exist?).with('/bin/sh').returns(true)
    Executioner::ClassMethods.find_executable('sh').should == '/bin/sh'
  end
  
  it "should be possible to find an executable advancing from a given path" do
    File.stubs(:exist?).with('/usr/bin/sh').returns(true)
    Executioner::ClassMethods.find_executable('sh', '/bin').should == '/usr/bin/sh'
  end
  
  it "should yield all found executables, but use the one for which the proc returns a truthful value" do
    File.stubs(:exist?).with('/bin/with_selection_proc').returns(true)
    File.stubs(:exist?).with('/usr/bin/with_selection_proc').returns(true)
    File.stubs(:exist?).with('/usr/local/bin/with_selection_proc').returns(true)
    File.stubs(:exist?).with('/opt/local/bin/with_selection_proc').returns(true)
    
    AClassThatUsesSubshells.executable(:with_selection_proc, :select_if => lambda { |executable| nil })
    lambda { @object.with_selection_proc('foo') }.should.raise Executioner::ExecutableNotFoundError
    
    AClassThatUsesSubshells.executable(:with_selection_proc, :select_if => lambda { |executable| executable == '/usr/bin/with_selection_proc' })
    @object.expects(:execute).with("/usr/bin/with_selection_proc foo", {:switch_stdout_and_stderr => false})
    @object.with_selection_proc('foo')
    
    AClassThatUsesSubshells.executable(:with_selection_proc, :select_if => lambda { |executable| executable == '/opt/local/bin/with_selection_proc' })
    @object.expects(:execute).with("/opt/local/bin/with_selection_proc foo", {:switch_stdout_and_stderr => false})
    @object.with_selection_proc('foo')
  end
  
  it "should define an instance method which raises a Executioner::ExecutableNotFoundError error if the executable could not be found" do
    lambda {
      @object.doesnotexistforsure 'right?'
    }.should.raise Executioner::ExecutableNotFoundError
  end
end