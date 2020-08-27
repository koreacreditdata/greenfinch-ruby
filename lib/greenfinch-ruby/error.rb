module Greenfinch

  # Greenfinch specific errors that are thrown in the gem.
  # In the default consumer we catch all errors and raise
  # Greenfinch specific errors that can be handled using a
  # custom error handler.
  class GreenfinchError < StandardError
  end
  
  class ConnectionError < GreenfinchError
  end
  
  class ServerError < GreenfinchError
  end


  # The default behavior of the gem is to silence all errors
  # thrown in the consumer.  If you wish to handle GreenfinchErrors
  # yourself you can pass an instance of a class that extends
  # Greenfinch::ErrorHandler to Greenfinch::Tracker on initialize.
  #
  #    require 'logger'
  #
  #    class MyErrorHandler < Greenfinch::ErrorHandler
  #
  #      def initialize
  #        @logger = Logger.new('mylogfile.log')
  #        @logger.level = Logger::ERROR
  #      end
  #    
  #      def handle(error)
  #        logger.error "#{error.inspect}\n Backtrace: #{error.backtrace}"
  #      end
  #
  #    end
  #
  #    my_error_handler = MyErrorHandler.new
  #    tracker = Greenfinch::Tracker.new(YOUR_GREENFINCH_TOKEN, my_error_handler)
  class ErrorHandler

    # Override #handle to customize error handling
    def handle(error)
      false
    end
  end
end
