

class ChildProcess 

  attr_reader :cmd, :port, :on_connect, :on_stdout, :on_stderr, :connected

  def initialize(opts = {})
    @cmd        = opts[:cmd]
    @ip         = opts[:ip] || '127.0.0.1'
    @port       = opts[:port]
    @on_connect = opts[:on_connect]
    @io_stdout  = opts[:io_stdout]
    @io_stderr  = opts[:io_stderr]
    @pid        = nil
    @connected  = false
  end

  def start
    o = {:out => '/dev/null', :err => '/dev/null'}
    o[:out] = @io_stdout if @io_stdout
    o[:err] = @io_stderr if @io_stderr
    @pid = Process.spawn(@cmd, o)
    loop do
      begin
        s = TCPSocket.open(@ip, @port)
        s.close
        @on_connect.call if @on_connect
        return
      rescue Errno::ECONNREFUSED
      end
    end
  end

  def stop
    begin
      Process.detach(@pid)
      Process.kill('TERM', @pid)
      Process.waitpid(@pid)
    rescue 
    end
  end

end

class ChildProcessManager

  def self.init
    @@managed_processes ||= {}
  end

  def self.spawn(processes)
    self.init

    if processes.is_a?(Hash)
      processes = [processes]
    end

    processes.each do |process_options|
      process_options[:ip] ||= '127.0.0.1'
      mpskey = "#{process_options[:ip]}:#{process_options[:port]}"

      if !@@managed_processes[mpskey]
        cp = ChildProcess.new(process_options)
        cp.start
        @@managed_processes[mpskey] = cp
      end
    end
  end

  def self.reap_all
    self.init

    @@managed_processes.each_value do |child_process|
      child_process.stop
      child_process = nil
    end
  end

  def self.reap_one(*args)
    self.init
    port = 0; ip = '127.0.0.1'

    if args.size == 1
      port = args[0]
    elsif args.size == 2
      ip = args[0]
      port = args[1]
    end
    if @@managed_processes["#{ip}:#{port}"]
      @@managed_processes["#{ip}:#{port}"].stop
      @@managed_processes["#{ip}:#{port}"] = nil
    end
  end
end
