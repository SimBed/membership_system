class Superadmin::BlastsController < Superadmin::BaseController
  def show
    @recipients = Client.all
    handle_filter
    @clients_to_add = Client.exclude(@recipients).order_by_first_name
    @message = session[:message]
    # @template_message = session[:template_message]
    @template_message = session[:greeting] == '1' ? "Hi [client name]\n" + session[:message] : session[:message]
    @recipient_list_size = @recipients.size
    @pagy, @recipients = pagy(@recipients, items: Rails.application.config_for(:constants)['recipient_pagination'])
  end

  # if i name the method create_message it cannot be found!!??
  def add_message
    # greeting = "Hi [client name]\n"
    session[:message] = params[:message]
    session[:greeting] = params[:greeting]
    # session[:template_message] = params[:greeting] == '1' ? greeting + params[:message] : params[:message]
    redirect_to blast_path
  end

  def filter
    clear_session(:filter_blast_packagee, :filter_blast_group_packagee, :filter_blast_group_packagee_not_rider, :filter_blast_nobody)
    set_blast_session(:packagee, :group_packagee, :group_packagee_not_rider, :nobody)
    redirect_to blast_path
  end

  def clear_filters
    clear_session(:filter_blast_packagee, :filter_blast_group_packagee, :filter_blast_group_packagee_not_rider, :filter_blast_nobody, :client_ids_remove, :client_ids_add)
    redirect_to blast_path
  end

  def test
    recipient = Rails.env.development? ? 'me' : 'boss'
    recipient_name = session[:greeting] == '1' ? 'blast tester' : nil
    Blast.new(receiver: recipient, message: template_message(session[:message], recipient_name)).send_whatsapp
    redirect_to blast_path
  end

  def blast_off
    @recipients = Client.all
    handle_filter
    max_recipient_blast_limit = Setting.max_recipient_blast_limit
    if @recipients.size > max_recipient_blast_limit
      flash[:warning] = t('.warning', max_recipient_blast_limit:)
      redirect_to blast_path and return
    end
    passes = 0
    errors = 0
    add_greeting = session[:greeting] == '1' ? true : false 
    @recipients.each do |recipient|
      recipient_name = add_greeting ? recipient.first_name : nil
      Blast.new(receiver: recipient, message: template_message(session[:message], recipient_name)).send_whatsapp
      passes += 1
    rescue
      next
      errors += 1
    end
    flash[:success] = t('.success', errors: ActionController::Base.helpers.pluralize(errors, "message"), passes: ActionController::Base.helpers.pluralize(passes, "message"))
    redirect_to blast_path
  end

  def remove_client
    session[:client_ids_remove] = client_ids_remove << params[:id]
    session[:client_ids_add].delete(params[:id])
    redirect_to blast_path
  end

  def add_client
    client_id = params[:client_id]
    session[:client_ids_add] = client_ids_add << client_id
    session[:client_ids_remove].delete(client_id)
    redirect_to blast_path
  end


  private

    def template_message(message_body, recipient_name)
      return "Hi #{recipient_name}\n" + session[:message] if recipient_name

      message_body
    end

    def client_ids_remove
      session[:client_ids_remove] ||= []
    end

    def client_ids_add
      session[:client_ids_add] ||= []
    end

    def handle_filter
      %w[packagee group_packagee group_packagee_not_rider nobody].each do |key|
        @recipients = @recipients.send(key) if session["filter_blast_#{key}"].present?
      end
      @recipients = @recipients.where.not(id: client_ids_remove).order_by_first_name
      unless client_ids_add.empty?
        ids = (client_ids_add + @recipients.unscope(:order).pluck(:id)).uniq
        @recipients = Client.where(id: ids).order_by_first_name
      end
      @excluded_clients = Client.where(id: client_ids_remove)
      @added_clients = Client.where(id: client_ids_add)
      # @clients.pluck(:id).to_json.bytesize
      # session[:client_ids] = @clients.pluck(:id).first(75)
    end

    #TODO: make dry - see set_session in sessions_helper.rb
    def set_blast_session(*args)
      args.each do |session_key|
        session["filter_blast_#{session_key}"] = params[session_key] || session["filter_blast_#{session_key}"]
      end
    end    
end
