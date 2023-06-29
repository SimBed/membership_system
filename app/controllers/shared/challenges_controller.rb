class Shared::ChallengesController < Admin::BaseController
  before_action :set_challenge, only: %i[show edit update destroy]

  def index
    @challenges = Challenge.order_by_name
  end

  def show
    @challenges = Challenge.order_by_name.map { |l| [l.name, l.id, { 'data-showurl' => shared_challenge_url(l.id) }] }
    @client_results = @challenge.results
  end

  def new
    @challenge = Challenge.new
    @challenges =  Challenge.order_by_name.map { |c| [c.name, c.id] }
  end

  def edit
    @challenges = Challenge.order_by_name.map { |c| [c.name, c.id] }
  end

  def create
    @challenge = Challenge.new(challenge_params)
    if @challenge.save
      flash[:success] = 'Challenge was successfully created.'
      redirect_to shared_challenges_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @challenge.update(challenge_params)
      flash[:success] = 'Challenge was successfully updated.'
      redirect_to shared_challenges_path
    else
      @challenges = Challenge.order_by_name.map { |c| [c.name, c.id] }
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @challenge.destroy
    flash[:success] = 'Challenge was successfully destroyed.'
    redirect_to shared_challenges_path
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:id])
  end

  def challenge_params
    params.require(:challenge).permit(:name, :metric, :metric_type, :challenge_id)
  end
end
