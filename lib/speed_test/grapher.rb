# frozen_string_literal: true
require 'gruff'
module SpeedTest
  class Grapher
    def initialize(title: 'SUPERPOWER', y_axis_label: 'MB/S(upl/down) / ms(ping)', hours: [], data: REGEXPS.keys)
      @creator = Gruff::Line.new(2000)
      @creator.title = title
      @creator.y_axis_label = y_axis_label
      @creator.y_axis_increment = 5
      @creator.labels = hours.each.with_object({}) do |hour, hash|
        hash[hash.size] = hour.hour[0..1]
      end
      data.each { |k| @creator.data(k, hours.map(&"avg_#{k}".intern)) }
      @creator.minimum_value = 0.0
    end

    def call(filename)
      @creator.write(filename)
    end
  end
end
