# frozen_string_literal: true
require 'gruff'

$regexps = {
  ping: /Ping: ((\d|\.)+)/,
  download: /Download: ((\d|\.)+)/,
  upload: /Upload: ((\d|\.)+)/
}.freeze

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

  ['max', 'min'].each do |str|
    $regexps.each_key do |key|
      name = "#{str}_#{key}"
      i_name = "@#{name}"
      cache_method(name, i_name, -> s { s.entries.send("#{str}_by") { |n| n.send(key) }.send(key) })
    end

    $regexps.each_key do |key|
      name = "avg_#{key}"
      i_name = "@#{name}"
      cache_method(name, i_name, -> s { s.entries.inject(0) { |m, a| m + a.send(key) } / s.entries.size })
    end

    def to_s
      sprintf("%s\tPing: %.2f\tDownload: %.2f\tUpload: %.2f", hour, avg_ping, avg_download, avg_upload)
    end
  end
end

$entries = []
$hours = []

Dir.glob(File.join(File.dirname(__FILE__), '*.txt')) do |file|
  string = IO.read(file)
  next if string.empty? || /Could not/ === string
  $entries << Entry.new(file.tr('_speed.txt', '').tr('/', ''), *$regexps.map do |_k, v|
    string.match(v).captures.first.to_f
  end)
end

$entries.group_by { |n| n.date[0..4] }.each do |k, v|
  next unless /\A\d{1,2}:00\z/ === k
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
