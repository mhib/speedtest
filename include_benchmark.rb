require 'benchmark/ips'

TEST = <<text
Ping: 33.286 ms
Download: 65.48 Mbit/s
Upload: 46.77 Mbit/s
text

TEST2 = 'Could not retrieve speedtest.net configuration: <urlopen error [Errno -2] Name or service not known>'

REGEXP = /Could not/
Benchmark.ips do |x|
  x.report("include?") do
    TEST.include? "Could not".freeze
    TEST2.include? "Could not".freeze
  end

  x.report("starts_with") do
    TEST.start_with? "Could not".freeze
    TEST2.start_with? "Could not".freeze
  end

  x.report("match") do
    TEST =~ REGEXP
    TEST2 =~ REGEXP

  end

  # Compare the iterations per second of the various reports!
  x.compare!
end
