require 'socket'

class ZeromqLogger

  attr_accessor :level, :log_tags


  def initialize
    super
    # Get info about our environment
    @ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.getnameinfo[0] 
    # Set up the logger
    @logger = ZeroLog.new
    @logger.init_log_data_sender "/tmp/sub_push_#{Process.pid}"
  end


  def debug?() @level <= 0; end
  def info?()  @level <= 1; end
  def warn?()  @level <= 2; end
  def error?() @level <= 3; end
  def fatal?() @level <= 4; end


  def add(level, msg, progname)
    return true if level < @level
    msg = progname if msg.blank?
    return true if msg.blank?       # Don't send
    #puts "Adding #{level} #{msg} #{progname}"
    milliseconds = (Time.now.utc.to_f * 1000).to_i
    data = { timestamp: milliseconds,
             ip:        @ip,
             pid:       Process.pid,
             service:   APP_NAME,
             level:     level,
             msg:       msg.kind_of?(String) ? msg : msg.inspect
           }
    @logger.log data
    true
  end

end
