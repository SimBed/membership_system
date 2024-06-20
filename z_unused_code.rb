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
    # self.bookings.no_amnesty.each do |booking|
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

  # unfortunately the clean way results in structurally incomaptible error. Workaround to this either by a) work on ruby objects (as for Client#active or
  # b) by putting all the joins/distincts at the end of the query as nar8789 answer https://stackoverflow.com/questions/40742078/relation-passed-to-or-must-be-structurally-compatible-incompatible-values-r
  # scope :problematic, -> { instructorless.or(self.incomplete).or(self.empty_class.has_instructor_cost) }
  # unfortunately this doesn't work either due to both .joins(:bookings) and .left_joins(:bookings) confusing the issue (removing the joins corrects the empty class undercount but increases the incomplete count)
  scope :problematic, -> { past(Setting.problematic_duration).instructorless
                          .or(where(bookings: {status: 'booked'})) # incomplete
                          .or(where(bookings: {id: nil})) # empty class
                          .or(where.not(instructor_rate: {rate: 0})) # has instructor cost
                          .joins(:instructor_rate).left_joins(:bookings).distinct} # dump all the joins/distinct at end of query

  # This works, but still needs a second query if chaining
  def Wkclass.problematic
  problematic_duration = Setting.problematic_duration
  query = "SELECT DISTINCT ON (id) * FROM
  (SELECT wkclasses.* from wkclasses
  LEFT JOIN bookings on wkclasses.id = bookings.wkclass_id
  JOIN instructor_rates ON instructor_rates.id = wkclasses.instructor_rate_id
  WHERE bookings.status = 'booked'
  OR wkclasses.instructor_id IS NULL
  OR (bookings.id IS NULL AND instructor_rates.rate != 0)) x
  WHERE start_time BETWEEN '#{Time.zone.now.advance(months: -problematic_duration)}' AND '#{Time.zone.now}'
  UNION
  SELECT DISTINCT ON (id) * FROM
  (SELECT wkclasses.* from wkclasses
  JOIN bookings on wkclasses.id = bookings.wkclass_id
  JOIN purchases ON purchases.id = bookings.purchase_id
  WHERE purchases.expiry_date + 1 < wkclasses.start_time
  AND bookings.status NOT IN ('no show', 'cancelled late')
  OR wkclasses.instructor_id IS NULL) x
  WHERE start_time BETWEEN '#{Time.zone.now.advance(months: -problematic_duration)}' AND '#{Float::INFINITY}'
  "
  # anticlimactic to get this far and still need another query
  Wkclass.where(id: ActiveRecord::Base.connection.exec_query(query).rows.map(&:first))
  # https://stackoverflow.com/questions/47893902/how-to-chain-raw-sql-queries-in-rails-or-how-to-return-an-activerecord-relation
  # This approach delivers an active-record relation which fails when chained, as happens when a filter applies
  #  Wkclass.select('*').from("(#{query}) AS x")
end