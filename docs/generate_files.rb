$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')
require 'speed_test'
require 'set'

DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'data')
IMG_PATH = File.join(File.expand_path(File.dirname(__FILE__)), 'images')
MONTHS = File.join(File.expand_path(File.dirname(__FILE__)), '_months')

def new_view(name)
<<EOF
---
layout: month
title: #{name}
---
<a href="{{'/images/#{name}.png' | prepend: site.baseurl }}"><img src="{{ '/images/#{name}.png' | prepend: site.baseurl }}" class="mid" alt="Open" /></a>
EOF
end

@months_set = Set.new
Dir.foreach(DATA_PATH) do |f|
  month = f[9..13]
  @months_set.add(month) if month
end

@months_set.sort_by { |month| month.split('-').reverse.join }.each_with_index do |month, id|
  data = SpeedTest::DataBuilder.new(File.join(DATA_PATH, "*#{month}_speed.txt")).call
  image_path = File.join(IMG_PATH, "#{month}.png")
  SpeedTest::Grapher.new(title: month, hours: data).call(image_path)
  File.open(File.join(MONTHS, "#{id}-#{month}.markdown"), 'w') do |f|
    f.write(new_view(month))
  end
end

