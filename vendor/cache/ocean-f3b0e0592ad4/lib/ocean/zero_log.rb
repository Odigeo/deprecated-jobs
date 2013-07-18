#
# This is the class that provides the interface to ZeroMQ, both for sending log
# data to a cluster of log servers, and for receiving it.
#
# The Rails logger is replaced in production by the initializer zero_mq_logger.rb.
#
# The worker daemons running on the log machines use the pull_server and 
# pull_worker methods in this class.
#

require 'ffi-rzmq'


class ZeroLog

  @@context = nil            # Only one per process


  def initialize
    super
    unless @@context
      #puts "Creating context"
      @@context = ZMQ::Context.new(1)
      #puts "Registering at_exit context terminator"
      at_exit { @@context.terminate
                #puts "Context terminated" 
              }
    end
  end


  def context
  	@@context
  end


  #
  # Register a trap handler for INT, so we can clean up properly
  #
  def trap_int(*sockets)
    sockets.each do |s|
      #puts "Registering at_exit socket closer"
      at_exit { s.setsockopt(ZMQ::LINGER, 0)
                s.close
                #puts "Socket closed" 
              }
    end
  end


  # ---------------------------------------------------------------------------
  #
  # Log data sender side (ruby, Ruby on Rails)
  #
  # ---------------------------------------------------------------------------

  def init_log_data_sender(sub_push="sub_push")
    # First create the server and let it bind, as this is required
    # when using inproc: bind must precede any connects.
    Thread.new(context) do |c|
      # Set up the server socket
      #puts "Starting SUB server"
      subscriber = c.socket(ZMQ::SUB)
      #puts "Binding to the SUB socket"
      subscriber.bind("inproc://#{sub_push}")
      subscriber.setsockopt(ZMQ::SUBSCRIBE, "")
      # Set up the PUSH socket
      loggers = context.socket(ZMQ::PUSH)
      LOG_HOSTS.each do |host|
        #puts "Connecting to the PULL server #{host}"
        loggers.connect("tcp://#{host}:10000")
      end
      # Connect SUB to PUSH via a queue and block
      ZMQ::Device.new(ZMQ::QUEUE, subscriber, loggers)
      # Context has been terminated, close sockets
      subscriber.setsockopt(ZMQ::LINGER, 0)
      subscriber.close
      loggers.setsockopt(ZMQ::LINGER, 0)
      loggers.close
      #puts "Closed sockets in other thread"
    end

    sleep 0.1

    # Next create the PUB socket and connect it to the other thread
    #puts "Creating the PUB socket"
    $log_publisher = context.socket(ZMQ::PUB) 
    trap_int($log_publisher)
    #puts "Connecting to the SUB server"
    $log_publisher.connect("inproc://#{sub_push}")
  end

  #
  # This is a combination of a PUB main thread log data sender,
  # pushing directly to the pull_server without the need for a local
  # aggregator.
  #
  def log(data)
    init_log_data_sender unless $log_publisher

    # Send the data
    json = data.to_json
    #puts "Sending message #{json}"
    $log_publisher.send_string(json)
    data
  end


  # ---------------------------------------------------------------------------
  #
  # Log service (aggregation) side
  #
  # ---------------------------------------------------------------------------

  PUSH_ADDRESS = "ipc://pull_worker.ipc"

  #
  # This is the PULL to PUSH server. It pushes the received data over IPC 
  # round-robin fashion to each PULL log worker on the machine.
  #
  def pull_server(address=PUSH_ADDRESS)
  	#puts "Starting PULL server"
  	puller = context.socket(ZMQ::PULL)
  	#puts "Binding to the PULL socket"
  	puller.bind("tcp://*:10000")
    # Set up the PUSH socket
    pusher = context.socket(ZMQ::PUSH)
    #puts "Binding to the PUSH socket"
    pusher.bind(address)
    # Trap everything
    trap_int(puller, pusher)
    # Connect PULL to PUSH via a queue
    ZMQ::Device.new(ZMQ::QUEUE, puller, pusher)
  end


  #
  # This is the PULL worker
  #
  def pull_worker(address=PUSH_ADDRESS)
  	#puts "Starting PULL worker"
  	puller = context.socket(ZMQ::PULL)
  	#puts "Connect to the PUSH socket"
    puller.connect(address)
    trap_int(puller)

  	while true do
  	  s = ''
  	  puller.recv_string(s)
  	  puts "Received: #{s}"
  	end
  end


end
