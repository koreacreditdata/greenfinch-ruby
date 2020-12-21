require 'base64'
require 'json'
require 'net/https'

module Greenfinch
  @@init_http = nil

  # This method exists for backwards compatibility. The preferred
  # way to customize or configure the HTTP library of a consumer
  # is to override Consumer#request.
  #
  # Ruby's default SSL does not verify the server certificate.
  # To verify a certificate, or install a proxy, pass a block
  # to Greenfinch.config_http that configures the Net::HTTP object.
  # For example, if running in Ubuntu Linux, you can run
  #
  #    Greenfinch.config_http do |http|
  #        http.ca_path = '/etc/ssl/certs'
  #        http.ca_file = '/etc/ssl/certs/ca-certificates.crt'
  #        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  #    end
  #
  # \Greenfinch Consumer and BufferedConsumer will call your block
  # to configure their connections
  def self.config_http(&block)
    @@init_http = block
  end

  # A Consumer receives messages from a Greenfinch::Tracker, and
  # sends them elsewhere- probably to Greenfinch's analytics services,
  # but can also enqueue them for later processing, log them to a
  # file, or do whatever else you might find useful.
  #
  # You can provide your own consumer to your Greenfinch::Trackers,
  # either by passing in an argument with a #send! method when you construct
  # the tracker, or just passing a block to Greenfinch::Tracker.new
  #
  #    tracker = Greenfinch::Tracker.new(YOUR_GREENFINCH_TOKEN) do |type, message|
  #        # type will be one of :event, :profile_update or :import
  #        @kestrel.set(ANALYTICS_QUEUE, [type, message].to_json)
  #    end
  #
  # You can also instantiate the library consumers yourself, and use
  # them wherever you would like. For example, the working that
  # consumes the above queue might work like this:
  #
  #     greenfinch = Greenfinch::Consumer
  #     while true
  #         message_json = @kestrel.get(ANALYTICS_QUEUE)
  #         greenfinch.send!(*JSON.load(message_json))
  #     end
  #
  # Greenfinch::Consumer is the default consumer. It sends each message,
  # as the message is recieved, directly to Greenfinch.
  class Consumer

    # Create a Greenfinch::Consumer. If you provide endpoint arguments,
    # they will be used instead of the default Greenfinch endpoints.
    # This can be useful for proxying, debugging, or if you prefer
    # not to use SSL for your events.
    def initialize(events_endpoint=nil,
                   update_endpoint=nil,
                   groups_endpoint=nil,
                   import_endpoint=nil)

      @events_endpoint = events_endpoint || 'https://event.kcd.partners/api/publish'
      @update_endpoint = update_endpoint || 'https://api.greenfinch.com/engage'
      @groups_endpoint = groups_endpoint || 'https://api.greenfinch.com/groups'
      @import_endpoint = import_endpoint || 'https://api.greenfinch.com/import'
    end

    # Send the given string message to Greenfinch. Type should be
    # one of :event, :profile_update or :import, which will determine the endpoint.
    #
    # Greenfinch::Consumer#send! sends messages to Greenfinch immediately on
    # each call. To reduce the overall bandwidth you use when communicating
    # with Greenfinch, you can also use Greenfinch::BufferedConsumer
    def send!(type, message)
      type = type.to_sym
      endpoint = {
        :event => @events_endpoint,
        :profile_update => @update_endpoint,
        :group_update => @groups_endpoint,
        :import => @import_endpoint,
      }[type]

      decoded_message = JSON.load(message)
      jwt_token = decoded_message["jwt_token"]
      service_name = decoded_message["service_name"]

      endpoint = "#{endpoint}/#{service_name}"

      form_data = decoded_message["data"]

      begin
        response_code, response_body = request(endpoint, form_data, jwt_token)
      rescue => e
        raise ConnectionError.new("Could not connect to Greenfinch, with error \"#{e.message}\".")
      end

      result = {}
      if response_code.to_i == 200
        begin
          result = JSON.parse(response_body.to_s)
        rescue JSON::JSONError
          raise ServerError.new("Could not interpret Greenfinch server response: '#{response_body}'")
        end
      else
        raise ServerError.new("Could not write to Greenfinch, server responded with #{response_code} returning: '#{response_body}'")
      end
    end

    # This method was deprecated in release 2.0.0, please use send! instead
    def send(type, message)
        warn '[DEPRECATION] send has been deprecated as of release 2.0.0, please use send! instead'
        send!(type, message)
    end

    # Request takes an endpoint HTTP or HTTPS url, and a Hash of data
    # to post to that url. It should return a pair of
    #
    # [response code, response body]
    #
    # as the result of the response. Response code should be nil if
    # the request never receives a response for some reason.
    def request(endpoint, form_data, jwt_token=nil)
      uri = URI(endpoint)

      headers = {
        "jwt" => jwt_token,
        "content-type" => "application/json",
        "label" => "ruby"
      }

      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = true
      client.open_timeout = 10
      client.continue_timeout = 10
      client.read_timeout = 10
      client.ssl_timeout = 10

      Greenfinch.with_http(client)

      response = client.request_post uri.request_uri, form_data.to_json, headers

      [response.code, response.body]
    end
  end

  # BufferedConsumer buffers messages in memory, and sends messages as
  # a batch.  This can improve performance, but calls to #send! may
  # still block if the buffer is full.  If you use this consumer, you
  # should call #flush when your application exits or the messages
  # remaining in the buffer will not be sent.
  #
  # To use a BufferedConsumer directly with a Greenfinch::Tracker,
  # instantiate your Tracker like this
  #
  #    buffered_consumer = Greenfinch::BufferedConsumer.new
  #    begin
  #        buffered_tracker = Greenfinch::Tracker.new(YOUR_GREENFINCH_TOKEN) do |type, message|
  #            buffered_consumer.send!(type, message)
  #        end
  #        # Do some tracking here
  #        ...
  #    ensure
  #        buffered_consumer.flush
  #    end
  #
  class BufferedConsumer
    MAX_LENGTH = 50

    # Create a Greenfinch::BufferedConsumer. If you provide endpoint arguments,
    # they will be used instead of the default Greenfinch endpoints.
    # This can be useful for proxying, debugging, or if you prefer
    # not to use SSL for your events.
    #
    # You can also change the preferred buffer size before the
    # consumer automatically sends its buffered events. The Greenfinch
    # endpoints have a limit of 50 events per HTTP request, but
    # you can lower the limit if your individual events are very large.
    #
    # By default, BufferedConsumer will use a standard Greenfinch
    # consumer to send the events once the buffer is full (or on calls
    # to #flush), but you can override this behavior by passing a
    # block to the constructor, in the same way you might pass a block
    # to the Greenfinch::Tracker constructor. If a block is passed to
    # the constructor, the *_endpoint constructor arguments are
    # ignored.
    def initialize(events_endpoint=nil, update_endpoint=nil, import_endpoint=nil, max_buffer_length=MAX_LENGTH, &block)
      @max_length = [max_buffer_length, MAX_LENGTH].min
      @buffers = {
        :event => [],
        :profile_update => [],
      }

      if block
        @sink = block
      else
        consumer = Consumer.new(events_endpoint, update_endpoint, import_endpoint)
        @sink = consumer.method(:send!)
      end
    end

    # Stores a message for Greenfinch in memory. When the buffer
    # hits a maximum length, the consumer will flush automatically.
    # Flushes are synchronous when they occur.
    #
    # Currently, only :event and :profile_update messages are buffered,
    # :import messages will be send immediately on call.
    def send!(type, message)
      type = type.to_sym

      if @buffers.has_key? type
        @buffers[type] << message
        flush_type(type) if @buffers[type].length >= @max_length
      else
        @sink.call(type, message)
      end
    end

    # This method was deprecated in release 2.0.0, please use send! instead
    def send(type, message)
        warn '[DEPRECATION] send has been deprecated as of release 2.0.0, please use send! instead'
        send!(type, message)
    end

    # Pushes all remaining messages in the buffer to Greenfinch.
    # You should call #flush before your application exits or
    # messages may not be sent.
    def flush
      @buffers.keys.each { |k| flush_type(k) }
    end

    private

    def flush_type(type)
      sent_messages = 0
      begin
        @buffers[type].each_slice(@max_length) do |chunk|
          data = chunk.map {|message| JSON.load(message)['data'] }
          @sink.call(type, {'data' => data}.to_json)
          sent_messages += chunk.length
        end
      rescue
        @buffers[type].slice!(0, sent_messages)
        raise
      end
      @buffers[type] = []
    end
  end

  private

  def self.with_http(http)
    if @@init_http
      @@init_http.call(http)
    end
  end
end
