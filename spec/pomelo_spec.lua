require('busted.runner')()
local sleep = require('system').sleep

local pomelo = require('pomelo')
pomelo.init({log='DISABLE'})

describe('pomelo', function()
  before_each(function()
    pomelo.removeAllListeners()

    print('pomelo.state() is ',pomelo.state())
    if pomelo.state() == 'CONNECTED' then
      local wait = true
      pomelo.once('disconnect',function()
        wait = false
      end)
      pomelo.disconnect()

      while wait do
        pomelo.poll()
        sleep(1)
      end
    end
  end)
  describe('.version()', function()
    it('returns the libpomelo2 version string', function()
      local v = pomelo.version()
      assert.are.equal('string', type(v))
      assert.is.truthy(v:match('^(%d+)%.(%d+)%.(%d+)%-(.+)$'))
    end)
  end)

  describe('.poll() #poll', function()
    it('polls all clients', function()
      pomelo.connect('127.0.0.1', 3010)

      assert.are.equal('CONNECTING', pomelo.state())
      sleep(1)
      pomelo.poll()
      sleep(1)
      pomelo.poll()
      sleep(1)
      pomelo.poll()
      assert.are.equal('CONNECTED', pomelo.state())
    end)
  end)
  describe('.connect()', function()
    it('connect to a pomelo server with default client config', function()
      pomelo.connect('127.0.0.1', 3010)
      assert.are.equal('CONNECTING', pomelo.state())
      sleep(1)
      pomelo.poll()
      assert.are.equal('CONNECTED', pomelo.state())
    end)
  end)

  describe('.disconnect()  #try', function()
    it('connect to a pomelo server', function()
      pomelo.connect('127.0.0.5', 3011)
      sleep(1)
      pomelo.poll()
      assert.is_true(pomelo.disconnect())
    end)
  end)

  describe('.request()', function()
    it('send request to pomelo server', function()
      print('begin call request --')
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      local callcnt = 0
      local callback = spy.new(function(err,msg)callcnt = callcnt + 1 print('callcnt is ',callcnt) print(err,msg) end)
      pomelo.request('connector.entryHandler.entry', '{"name": "test"}', 10, callback)
      sleep(2)
      pomelo.poll()
      assert.spy(callback).was.called(1)
      assert.spy(callback).was.called_with(
        nil,
        '{"code":200,"msg":"game server is ok."}'
      )
    end)
    it('timeout are optional', function()
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      local callback = spy.new(function()end)
      assert.has_no.errors(function()
        pomelo.request('connector.entryHandler.entry', '{"name": "test"}', callback)
      end)
      assert.has_error(function()
        pomelo.request('connector.entryHandler.entry', '{"name": "test"}')
      end)
      assert.has_error(function()
        pomelo.request('connector.entryHandler.entry', '{"name": "test"}', 10)
      end)
      sleep(2)
      pomelo.poll()
      assert.spy(callback).was.called(1)
      assert.spy(callback).was.called_with(
        nil,
        '{"code":200,"msg":"game server is ok."}'
      )
    end)
  end)

  describe('.notify()', function()
    it('send notify to pomelo server', function()
      pomelo.on('onPush', function(msg)
        assert.are.equal('{"content":"test content","topic":"test topic","id":42}', msg)
      end)
      pomelo.on('onPush', function(msg)
        assert.are.equal('{"content":"test content","topic":"test topic","id":42}', msg)
      end)
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      local s = spy.new(function() end)
      pomelo.notify('test.testHandler.notify', '{"content": "test content"}', 10, s)
      sleep(2)
      pomelo.poll()
      assert.spy(s).was.called(1)
    end)
    it('timeout and callback are optional', function()
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()

      local timeout_test_cnt = 0
      local s = spy.new(function() timeout_test_cnt = timeout_test_cnt + 1 print('timeout_test_cnt ',timeout_test_cnt)end)
      assert.has_no.errors(function()
        pomelo.notify('test.testHandler.notify', '{"content": "test content"}', 10)
      end)
      assert.has_no.errors(function()
        pomelo.notify('test.testHandler.notify', '{"content": "test content"}', s)
      end)
      assert.has_no.errors(function()
        pomelo.notify('test.testHandler.notify', '{"content": "test content"}')
      end)
      sleep(2)
      pomelo.poll()
      assert.spy(s).was.called(1)
    end)
  end)

  describe('.on()', function()
    it('adds event listener to client', function()
      local s = spy.new(function() end)
      pomelo.on('connect', s)
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      pomelo.disconnect()
      sleep(1)
      pomelo.poll()
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      assert.spy(s).was.called(2)
    end)
  end)

  describe('.once()', function()
    it('adds event listener to client', function()
      local s = spy.new(function() end)
      pomelo.once('connect', s)
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      pomelo.disconnect()
      sleep(1)
      pomelo.poll()
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      assert.spy(s).was.called(1)
    end)
  end)

  describe('.off()', function()
    it('removes event listener', function()
      local s = spy.new(function() print('off function *********') end)
      pomelo.on('connect', s)

      print('pre off ')
      pomelo.off('connect', s)

      print('pre connect ')
      pomelo.connect('127.0.0.1', 3010)
      sleep(1)
      pomelo.poll()
      assert.spy(s).was.called(0)
    end)
  end)

  describe('.listeners()', function()
    it('returns emtpy when no listeners registered', function()
      assert.are.same({}, pomelo.listeners('connect'))
    end)
    it('return the array of listeners registered', function()
      local function f() end
      pomelo.on('connect', f)
      assert.are.same({f}, pomelo.listeners('connect'))
    end)
  end)

  describe('.state()', function()
    it('new created client are in `INITED` state', function()
      assert.are.equal('INITED', pomelo.state())
    end)
    it('call connect() will turn client to CONNECTING', function()
      pomelo.connect('127.0.0.1', 1234)
      assert.are.equal('CONNECTING', pomelo.state())
    end)
  end)
end)
