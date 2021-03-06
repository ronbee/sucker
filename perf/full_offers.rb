require File.expand_path('../helper', __FILE__)

trap('INT') { exit 0 }

timestamps = {
  :us => [],
  :uk => [],
  :de => [],
  :ca => [],
  :fr => [],
  :jp => []
}

batch_size = ARGV[0].to_i
batch_size = 20 if batch_size == 0

printed_at = Time.now
interface = ARGV[1]

asins_fixture.each_slice(batch_size) do |asins|
  threads = timestamps.keys.map do |locale|
    Thread.new do
      worker = Sucker.new(
        :locale => locale,
        :key    => amazon["key"],
        :secret => amazon["secret"])
      worker.curl_opts { |c| c.interface = interface } unless interface !~ /\S/
      worker << {
        "Operation"                       => "ItemLookup",
        "ItemLookup.Shared.IdType"        => "ASIN",
        "ItemLookup.Shared.Condition"     => "All",
        "ItemLookup.Shared.MerchantId"    => "All",
        "ItemLookup.Shared.ResponseGroup" => "OfferFull"
      }
      worker << { "ItemLookup.1.ItemId" => asins[0, 10] }
      if batch_size > 10
        worker << { "ItemLookup.2.ItemId" => asins[10, 10] }
      end

      resp = worker.get
      Thread.current[:locale] = locale
      if resp.valid?
        Thread.current[:timestamp] = Time.now
      else
        p resp.body
      end
    end
  end

  threads.map do |thread|

    # I expect the thread to complete in two seconds
    next unless thread.join(1.0)

    timestamp = thread[:timestamp]
    if timestamp
      timestamps[thread[:locale]].push(timestamp)
    end
  end

  # Print rates every 5 seconds
  if Time.now - printed_at > 5.0
    puts Time.now.strftime("%H:%M:%S").center(38, '-')
    printed_at = Time.now
    timestamps.each do |locale, values|
      average = (values.
        select { |ts| printed_at - ts < 60.0 }.size / 60.0).
        round(3)
      puts [locale, values.size, average].
        map { |w| w.to_s.center(10) }.join(' | ')
    end
  end
end
