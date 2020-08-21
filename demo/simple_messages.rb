$LOAD_PATH << "/Users/jambo/Dev/mixpanel-ruby/lib"
require 'mixpanel-ruby'

if __FILE__ == $0
  # Replace this with the token from your project settings
  DEMO_TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE1OTE2NzIwMzksImV4cCI6MzY4NTI3MDAwMDAwMCwic2VydmljZV9uYW1lIjoiZmx5Y2F0Y2hlciJ9.lY6RVf1rsaYkuLCLfCs4cKFRNTvcbmZcR2IXEYZkdzw'
  mixpanel_tracker = Mixpanel::Tracker.new(DEMO_TOKEN)
  mixpanel_tracker.track('ID', 'Script run')
end
