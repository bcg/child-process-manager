require 'bundler'

Bundler.setup(:default, :test, :em_redis)

require 'eventmachine'
require 'em-redis'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. lib child-process-manager]))
require 'minitest/unit'
require 'minitest/spec'
require 'minitest/mock'
require 'em-spec/test'


class EMRedisTestCase < MiniTest::Unit::TestCase
  include EventMachine::Test

  def setup
    cpm = ChildProcessManager.spawn({
      :cmd  => 'redis-server',
      :port => 6379,
      :on_connect => done,
      :on_stdout => nil,
      :on_stderr => nil
    })
  end

  def teardown
    ChildProcessManager.reap_all
    done
  end

  def test_connected
    @r = EM::Protocols::Redis.connect
    EM.next_tick do
      assert_equal false, @r.error?
      done
    end
  end

  def test_connected_two
    @r = EM::Protocols::Redis.connect
    EM.next_tick do
      assert_equal false, @r.error?
      done
    end
  end

  def test_reconnect
    @r = EM::Protocols::Redis.connect
    ChildProcessManager.reap_all
    EM.next_tick do
      @r.get("test") do |res|
        assert nil, res
        assert_equal true, @r.error?
      end
    end
    cpm = ChildProcessManager.spawn({
      :cmd  => 'redis-server',
      :port => 6379,
    })
    EM.add_timer(2) do
      assert_equal false, @r.error?
      done
    end
  end

end

MiniTest::Unit.new.run ARGV
