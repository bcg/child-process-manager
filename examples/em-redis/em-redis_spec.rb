require 'bundler'

Bundler.setup(:default, :test, :em_redis)

require 'eventmachine'
require 'rspec'
require 'em-spec/rspec'
require 'em-redis'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. lib child-process-manager]))

describe EM::Protocols::Redis do
  include EM::Spec

  before(:each) do
    ChildProcessManager.spawn([{
      :cmd  => 'redis-server',
      :port => 6379
    },{
      :cmd  => 'echo "port 12345" | redis-server -',
      :port => 12345
    }])
    done
  end

  after(:each) do
    ChildProcessManager.reap_all
    done
  end

  it 'should connect' do
    @r = EM::Protocols::Redis.connect
    @r.error?.should be_false
    done
  end

  it 'should reap_one then reap_all' do
    ChildProcessManager.reap_one(12345)
    ChildProcessManager.reap_all
    ChildProcessManager.managed_processes.should == {}
    done
  end

  it 'should not be connected after redis goes down' do
    @r = EM::Protocols::Redis.connect
    EM.next_tick do
      ChildProcessManager.reap_one(6379)
      EM.add_timer(0.1) do
        @r.error?.should be_true
        done
      end
    end
  end

end

describe EM::Protocols::Redis do
  include EM::Spec

  it 'should reconnect' do
    ChildProcessManager.spawn({
      :cmd  => 'redis-server',
      :port => 6379,
    })
    @r = EM::Protocols::Redis.connect
    @r.get('c') do |res|
      res.should == nil
    end
    ChildProcessManager.reap_one(6379)
    ChildProcessManager.spawn({
      :cmd  => 'redis-server',
      :port => 6379,
    })
    EM.add_timer(1.5) do # Redis reconnects after 1 second
      EM.next_tick do
        @r.error?.should be_false
        ChildProcessManager.reap_one(6379)
        done
      end
    end
  end

end
