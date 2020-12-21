require 'time'

require 'greenfinch-ruby/consumer'
require 'greenfinch-ruby/error'

module Greenfinch

  # Handles formatting Greenfinch event tracking messages
  # and sending them to the consumer. Greenfinch::Tracker
  # is a subclass of this class, and the best way to
  # track events is to instantiate a Greenfinch::Tracker
  #
  #     tracker = Greenfinch::Tracker.new(YOUR_GREENFINCH_TOKEN) # Has all of the methods of Greenfinch::Event
  #     tracker.track(...)
  #
  class Events

    # You likely won't need to instantiate an instance of
    # Greenfinch::Events directly. The best way to get an instance
    # is to use Greenfinch::Tracker
    #
    #     # tracker has all of the methods of Greenfinch::Events
    #     tracker = Greenfinch::Tracker.new(YOUR_GREENFINCH_TOKEN)
    #
    def initialize(token, service_name, debug, error_handler=nil, use_internal_domain: false, &block)
      @token = token
      @service_name = service_name
      @error_handler = error_handler || ErrorHandler.new

      events_endpoint =
        if debug
          if use_internal_domain
            "https://internal-event-staging.kcd.partners/api/publish"
          else
            "https://event-staging.kcd.partners/api/publish"
          end
        else
          if use_internal_domain
            "https://internal-event.kcd.partners/api/publish"
          else
            "https://event.kcd.partners/api/publish"
          end
        end

      if block
        @sink = block
      else
        consumer = Consumer.new(events_endpoint)
        @sink = consumer.method(:send!)
      end
    end

    # Notes that an event has occurred, along with a distinct_id
    # representing the source of that event (for example, a user id),
    # an event name describing the event and a set of properties
    # describing that event. Properties are provided as a Hash with
    # string keys and strings, numbers or booleans as values.
    #
    #     tracker = Greenfinch::Tracker.new(YOUR_GREENFINCH_TOKEN)
    #
    #     # Track that user "12345"'s credit card was declined
    #     tracker.track("12345", "Credit Card Declined")
    #
    #     # Properties describe the circumstances of the event,
    #     # or aspects of the source or user associated with the event
    #     tracker.track("12345", "Welcome Email Sent", {
    #         'Email Template' => 'Pretty Pink Welcome',
    #         'User Sign-up Cohort' => 'July 2013'
    #     })
    def track(distinct_id, event, properties={}, ip=nil)
      properties = {
        'user_id' => distinct_id,
        'time' => Time.now.to_i,
        'mp_lib' => 'ruby',
        '$lib_version' => Greenfinch::VERSION,
      }.merge(properties)
      properties['ip'] = ip if ip

      data = {
        'event' => event,
        'prop' => properties,
      }

      message = {
        'data' => data,
        'jwt_token' => @token,
        'service_name' => @service_name,
      }

      ret = true

      begin
        @sink.call(:event, message.to_json)
      rescue GreenfinchError => e
        @error_handler.handle(e)
        ret = false
      end

      ret
    end

    # Imports an event that has occurred in the past, along with a distinct_id
    # representing the source of that event (for example, a user id),
    # an event name describing the event and a set of properties
    # describing that event. Properties are provided as a Hash with
    # string keys and strings, numbers or booleans as values.  By default,
    # we pass the time of the method call as the time the event occured, if you
    # wish to override this pass a timestamp in the properties hash.
    #
    #     tracker = Greenfinch::Tracker.new(YOUR_GREENFINCH_TOKEN)
    #
    #     # Track that user "12345"'s credit card was declined
    #     tracker.import("API_KEY", "12345", "Credit Card Declined")
    #
    #     # Properties describe the circumstances of the event,
    #     # or aspects of the source or user associated with the event
    #     tracker.import("API_KEY", "12345", "Welcome Email Sent", {
    #         'Email Template' => 'Pretty Pink Welcome',
    #         'User Sign-up Cohort' => 'July 2013',
    #         'time' => 1369353600,
    #     })
    def import(api_key, distinct_id, event, properties={}, ip=nil)
      properties = {
        'distinct_id' => distinct_id,
        'token' => @token,
        'time' => Time.now.to_i,
        'mp_lib' => 'ruby',
        '$lib_version' => Greenfinch::VERSION,
      }.merge(properties)
      properties['ip'] = ip if ip

      data = {
        'event' => event,
        'properties' => properties,
      }

      message = {
        'data' => data,
        'api_key' => api_key,
      }

      ret = true
      begin
        @sink.call(:import, message.to_json)
      rescue GreenfinchError => e
        @error_handler.handle(e)
        ret = false
      end

      ret
    end
  end
end
