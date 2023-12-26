  # Use a class method with an argument to call send_reminder method rather than call send_reminder directly
  # on an wkclass instance. As Delayed::Job works by saving an object to database (in yml form), this approach considerably
  # reduces the volume of data stored in the delayed_jobs table (per Railscast)
  class << self
    def send_reminder(id)
      find(id).send_reminder
    end
    # handle_asynchronously :send_reminder, run_at: proc { Time.zone.now + 30.seconds }
    handle_asynchronously :send_reminder, run_at: proc { 30.seconds.from_now }
  end

  def send_reminder
    file_path = Rails.root.join('delayed.txt')
    File.write(file_path, "delayed job processing at #{Time.zone.now}")
    # Wkclass.last.update(instructor_cost:100)
    # account_sid = Rails.configuration.twilio[:account_sid]
    # auth_token = Rails.configuration.twilio[:auth_token]
    # from = Rails.configuration.twilio[:whatsapp_number]
    # to = Rails.configuration.twilio[:me]
    # client = Twilio::REST::Client.new(account_sid, auth_token)
    # time_str = ((self.start_time).localtime).strftime("%I:%M%p on %b. %d, %Y")
    # self.attendances.no_amnesty.each do |booking|
    #     body = "Hi #{self.purchase.client.first_name}. Just a reminder that you have a class coming up at #{time_str}."
    #     message = client.messages.create(
    #       from: "whatsapp:#{from}",
    #       to: "whatsapp:#{to}",
    #       body: body
    #     )
    #   end
  end
  # handle_asynchronously :send_reminder, :run_at => Proc.new { |i| i.when_to_run }

  # def when_to_run
  #   minutes_before_class = 60.minutes
  #   start_time - minutes_before_class
  # end