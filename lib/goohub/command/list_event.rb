class GoohubCLI < Clian::Cli
  ################################################################
  # Command: list_event
  ################################################################
  desc "list_event CALENDAR_ID START_MONTH ( END_MONTH )", "show events of google or redis"
  option :end, :desc => "specify end month of range (year-month)"
  option :input, :default => "google", :desc => "specify input destination (google or kvs:host:port:name)"
  option :output, :default => "stdout", :desc => "specify output destination (google or kvs:host:port:name) "
  long_desc <<-LONGDESC
    `goohub list_event` gets and stores events between START_MONTH ( and END_MONTH ) found by CALENDAR_ID

    When output is "redis", if other parameter( host or port or name ) is not set,

    host: "localhost", port: "6379", name: "0" is set by default.
  LONGDESC

  def list_event(calendar_id, start_month, end_month="#{Date.today.year}-#{Date.today.month}")
    start = Goohub::DateFrame::Monthly.new(start_month)

    if options[:input] != "google"
      input_kvs = create_kvs(options[:input])
    end

    if options[:output] != "google" and options[:output] != "stdout"
      output_kvs = create_kvs(options[:output])
    end

    start.each_to(end_month) do |frame|
      params = [calendar_id, frame.year.to_s, frame.month.to_s]
      puts "Get events of "+ params[1] + "-" + params[2]

      if options[:input] == "google"
        min = frame.to_s
        max = (frame.next_month - Rational(1, 24 * 60 * 60)).to_s # Calculate end of frame for Google Calendar API
        raw_resource = client.list_events(params[0], time_max: max, time_min: min, single_events: true)

      else
        raw_resource = input_kvs.load(params.join('-'))
      end
      events = Goohub::Resource::EventCollection.new(raw_resource)
      if options[:output] == "stdout"
        events.each do |item|
          puts item.summary.to_s + "(" + item.id.to_s + ")"
        end
      elsif options[:output] == "google"
        puts "Not implemented"
      else
        print "Status: "
        puts output_kvs.store(params.join('-'), events.to_json)
      end
    end
  end

  private

  def create_kvs(params)
    kvs, host, port, db_name = params.split(":")
    if !kvs or kvs == ""
      kvs = "redis"
    end
    if !host or host == ""
      host = "localhost"
    end
    if !port or port == ""
      port = "6379"
    end
    if !db_name or db_name == ""
      db_name = "0"
    end
    return Goohub::DataStore.create(kvs.intern, {:host => host, :port => port.to_i, :db => db_name.to_i})
  end

end
