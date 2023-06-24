class Shared::ChallengesController < Admin::BaseController
  before_action :set_challenge, only: %i[show edit update destroy]

  def index
    @challenges = Challenge.all
  end

  def show
    @challenges = Challenge.all.map { |l| [l.name, l.id, { 'data-showurl' => shared_challenge_url(l.id) }] }
    @clients = @challenge.positions
  end

  def new
    @challenge = Challenge.new
  end

  def edit
  end

  def create
    @challenge = Challenge.new(challenge_params)
    if @challenge.save
      flash[:success] = "Challenge was successfully created."
      redirect_to shared_challenges_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @challenge.update(challenge_params)
      flash[:success] = "Challenge was successfully updated."
      redirect_to shared_challenges_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @challenge.destroy
    flash[:success] = "Challenge was successfully destroyed."
    redirect_to shared_challenges_path
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:id])
  end

  def challenge_params
    params.require(:challenge).permit(:name, :metric, :metric_type)
  end
end
