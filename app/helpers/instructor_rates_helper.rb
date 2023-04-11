module InstructorRatesHelper
  def group_or_pt(group)
    group ? "Group" : "PT"
  end
end
