module SpeedTest
  REGEXPS = Hash[%i(ping download upload).map { |n| [n, /#{n.to_s.capitalize}: ((\d|\.)+)/] } ].freeze
end

require 'method_cachable'
require 'speed_test/data_builder'
require 'speed_test/entry'
require 'speed_test/grapher'
require 'speed_test/hour'
