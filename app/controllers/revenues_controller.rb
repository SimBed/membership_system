class RevenuesController < ApplicationController
  def index
    @workout_groups = WorkoutGroup.all
  end
end
