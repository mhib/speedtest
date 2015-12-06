require 'gruff'
$regexps = {
  ping: /Ping: ((\d|\.)+)/,
  download: /Download: ((\d|\.)+)/,
  upload: /Upload: ((\d|\.)+)/
}.freeze

Entry = Struct.new(:date, :upload, :download, :ping)
Hour = Struct.new(:hour, :entries) do
  ['max', 'min'].each do |str|
    $regexps.each_key do |key|
      name = "#{str}_#{key}".freeze
      i_name = "@#{name}".freeze
      define_method name do
        if instance_variable_defined?(i_name)
          instance_variable_get(i_name)
        else
          instance_variable_set(i_name, entries.send("#{str}_by") { |n| n.send(key) }.send(key))
        end
      end
    end

    $regexps.each_key do |key|
      name = "avg_#{key}".freeze
      i_name = "@#{name}".freeze
      define_method name do
        if instance_variable_defined?(i_name)
          instance_variable_get(i_name)
        else
          instance_variable_set(i_name, (entries.inject(0) { |m, a| m + a.send(key) } / entries.size).round)
        end
      end
    end

    def to_s
      "#{hour}\tPing: #{avg_ping}\tDownload: #{avg_download}\tUpload: #{avg_upload}"
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
g.write('graph.png')
