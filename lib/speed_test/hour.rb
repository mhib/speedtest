module SpeedTest
  Hour = Struct.new(:hour, :entries) do
    extend MethodCachable

    %w(min max).each do |str|
      REGEXPS.each_key do |key|
        cache_method "#{str}_#{key}", "@#{str}_#{key}" do
          entries.send("#{str}_by") { |n| n.send(key) }.send(key)
        end
      end
    end

    REGEXPS.each_key do |key|
      cache_method "avg_#{key}", "@avg_#{key}" do
        entries.inject(0) { |m, a| m + a.send(key) } / entries.size
      end
    end

    cache_method 'to_s', '@to_s' do
      REGEXPS.keys.each_with_object String.new("#{hour}\t") do |a, m|
        m << sprintf(
          "%s: %.2f(Max/Min: %.2f/%.2f)\t",
          a.to_s.capitalize,
          *(%w(avg max min).map { |s| send("#{s}_#{a}") })
        )
      end.chomp("\t")
    end
  end
end
