require 'open3'

module Executioner
  class ExecutionerError < StandardError; end
  class ProcessError < ExecutionerError; end
  class ExecutableNotFoundError < ExecutionerError; end
  
  SEARCH_PATHS = %W{ #{File.expand_path('~/bin')} /bin /usr/bin /usr/local/bin /opt/homebrew/bin /opt/local/bin }
  
  class << self
    # Assign a logger if you want to log commands and options.
    attr_accessor :logger
    
    def included(klass)
      klass.extend ClassMethods
    end
  end
  
  def execute(command, options={})
    command = "#{options[:env].map { |k,v| "#{k}='#{v}'" }.join(' ')} #{command}" if options[:env]
    
    Executioner.logger.debug("Executing: `#{command}'") if Executioner.logger
    
    output = nil
    Open3.popen3(command) do |stdin, stdout, stderr|
      stdout, stderr = stderr, stdout if options[:switch_stdout_and_stderr]
      
      output = stdout.gets(nil)
      if output.nil? && (error_message = stderr.gets(nil))
        if error_message =~ /:in\s`exec':\s(.+)\s\(.+\)$/
          error_message = $1
        end
        raise ProcessError, "Command: \"#{command}\"\nOutput: \"#{error_message.chomp}\""
      end
    end
    output
  end
  module_function :execute
  
  def concat_args(args)
    args.map { |a,v| "-#{a} #{v}" }.join(' ')
  end
  
  def queue(command)
    @commands ||= []
    @commands << command
  end
  
  def queued_commands
    @commands ? @commands.join(' && ') : ''
  end
  
  def execute_queued(options={})
    execute(queued_commands, options)
    @commands = []
  end
  
  module ClassMethods
    # Register an executable with the class.
    #
    #   executable :ppane
    #
    # You can configure the environment to use for each call to the executable.
    #
    #   executable :rails, :env => { 'RAILS_ENV' => 'production' }
    #
    # In case the executable is outside regular paths, you can specify a
    # particular path.
    #
    #   executable :heap, :path => '/Developer/usr/bin/heap'
    #
    # The method you use to call the binary returns it's output in a a string
    # sometimes the useful information is in +stderr+ instead of +stdout+.
    # This happens sometimes in application which show progress. You can
    # switch the output streams to capture +stderr+ instead of +stdout+.
    #
    #   executable :lame, :switch_stdout_and_stderr => true
    #
    # If you have some particular need to select a specific path over another
    # you can select it using a proc.
    #
    #   executable :gcc, :select_if => { |e| File.ftype(e) != 'link' }
    #   executable :gcc, :select_if => { |e| e.start_with?('/Developer') }
    #
    # Both symbols and strings are allowed for names.
    #
    #   executable 'aclocal-1.10'
    #
    def executable(executable, options={})
      options[:switch_stdout_and_stderr] ||= false
      options[:use_queue]                ||= false
      
      executable = executable.to_s if executable.is_a? Symbol
      use_queue = options.delete(:use_queue)
      
      if selection_proc = options.delete(:select_if)
        advance_from = nil
        while executable_path = find_executable(executable, advance_from)
          break if selection_proc.call(executable_path)
          advance_from = File.dirname(executable_path)
        end
      else
        executable_path = options[:path] || find_executable(executable)
      end
      
      if executable_path
        if use_queue
          body = "queue(\"#{executable_path} \#{args}\")"
        else
          body = "execute(\"#{executable_path} \#{args}\", #{options.inspect}.merge(options))"
        end
      else
        body = "raise Executioner::ExecutableNotFoundError, \"Unable to find the executable '#{executable}' in: #{Executioner::SEARCH_PATHS.join(', ')}\""
      end
      
      class_eval "def #{executable.gsub(/-/, '_')}(args, options = {}); #{body}; end", __FILE__, __LINE__
    end
    
    # Finds the first occurence of the specified executable in Executioner::SEARCH_PATHS
    def find_executable(executable, advance_from = nil)
      search_paths = Executioner::SEARCH_PATHS
      search_paths = search_paths[(search_paths.index(advance_from) + 1)..-1] if advance_from
      
      if executable_in_path = search_paths.find { |path| File.exist?(File.join(path, executable)) }
        File.join(executable_in_path, executable)
      end
    end
    module_function :find_executable
  end
end