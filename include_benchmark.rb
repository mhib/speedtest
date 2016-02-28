require 'benchmark/ips'

TEST = "
Ping: 33.286 ms
Download: 65.48 Mbit/s
Upload: 46.77 Mbit/s
".freeze

TEST2 = 'Could not retrieve speedtest.net configuration: <urlopen error [Errno -2] Name or service not known>'.freeze

REGEXP = /Could not/.freeze
Benchmark.ips do |x|
  x.report("include?", 'TEST.include?("Could not".freeze);TEST2.include?("Could not".freeze);' * 1000)

  x.report("starts_with", 'TEST.start_with?("Could not".freeze); TEST2.start_with?("Could not".freeze);' * 1000)

  x.report("match", 'TEST =~ REGEXP; TEST2 =~ REGEXP;' * 1000)

  # Compare the iterations per second of the various reports!
  x.compare!
end
