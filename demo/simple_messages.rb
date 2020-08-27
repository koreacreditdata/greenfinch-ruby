$LOAD_PATH << "/Users/terry/Documents/Github/greenfinch-ruby/lib"
require 'greenfinch-ruby'

if __FILE__ == $0
  # Replace this with the token from your project settings
  DEMO_TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE1OTE2NzIwMzksImV4cCI6MzY4NTI3MDAwMDAwMCwic2VydmljZV9uYW1lIjoiZmx5Y2F0Y2hlciJ9.lY6RVf1rsaYkuLCLfCs4cKFRNTvcbmZcR2IXEYZkdzw'
  tracker = Greenfinch::Tracker.new(DEMO_TOKEN, 'flycatcher', true)
  tracker.track('ID', 'Script run!!', {p1:'p1p1',p2:'p2p2', p3:123})
end
