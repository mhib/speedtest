# frozen_string_literal: true
require 'gruff'

$regexps = Hash[%i(ping download upload).map { |n| [n, /#{n.to_s.capitalize}: ((\d|\.)+)/] } ]

Entry = Struct.new(:date, :upload, :download, :ping)
Hour = Struct.new(:hour, :entries) do
  def self.cache_method(name, i_name, block)
    define_method name do
      if instance_variable_defined?(i_name)
        instance_variable_get(i_name)
      else
        instance_variable_set(i_name, block.call(self))
      end
    end
  end

  %w(min max).each do |str|
    $regexps.each_key do |key|
      cache_method(
        "#{str}_#{key}",
        "@#{str}_#{key}",
        -> s { s.entries.send("#{str}_by") { |n| n.send(key) }.send(key) }
      )
    end
  end

  $regexps.each_key do |key|
    cache_method(
      "avg_#{key}",
      "@avg_#{key}",
      -> s { s.entries.inject(0) { |m, a| m + a.send(key) } / s.entries.size }
    )
  end

  def to_s
    @to_s ||= $regexps.keys.each_with_object String.new("#{hour}\t") do |a, m|
      m << sprintf(
        "%s: %.2f(Max/Min: %.2f/%.2f)\t",
        a.to_s.capitalize,
        *(%w(avg max min).map { |s| self.send("#{s}_#{a}") })
      )
    end.chomp("\t")
  end
end

$entries = []
$hours = []

Dir.glob(File.join(File.dirname(__FILE__), '*.txt')) do |file|
  string = IO.read(file)
  next if string.empty? or string.start_with? 'Could not'
  $entries << Entry.new(file.tr('_speed.txt', '').tr('/', ''), *$regexps.map do |_k, v|
    string.match(v).captures.first.to_f
  end)
end

$entries.group_by { |n| n.date[0..4] }.each do |k, v|
  next unless k.end_with? ':00'
  $hours << Hour.new(k, v)
end
$hours.sort_by!(&:hour)

puts "Average stats:"
$hours.each { |n| puts n.to_s }

puts "Best stats"
$regexps.each_key do |n|
  entry = $entries.send(n == :ping ? :min_by : :max_by, &n)
  puts "#{n.to_s.capitalize} #{entry.date}\t#{entry.send(n)}"
end

puts "Worst stats"
$regexps.each_key do |n|
  entry = $entries.send(n == :ping ? :max_by : :min_by, &n)
  puts "#{n.to_s.capitalize} #{entry.date}\t#{entry.send(n)}"
end

g = Gruff::Line.new(2000)
g.title = "SUPERPOWER"
g.y_axis_label = "MB/S(upl/down) / ms(ping)"
g.labels = $hours.each.with_object({}) do |hour, hash|
  hash[hash.size] = hour.hour[0..1]
end
$regexps.each_key do |k|
  g.data(k, $hours.map(&"avg_#{k}".intern))
end
g.minimum_value = 0.0
g.y_axis_increment = 5
g.write("graph_#{Time.now.to_s[0..9]}.png")
