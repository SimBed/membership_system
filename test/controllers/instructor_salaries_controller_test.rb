require "test_helper"

class InstructorSalariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @instructor_salary = instructor_salaries(:one)
  end

  test "should get index" do
    get instructor_salaries_url
    assert_response :success
  end

  test "should get new" do
    get new_instructor_salary_url
    assert_response :success
  end

  test "should create instructor_salary" do
    assert_difference('InstructorSalary.count') do
      post instructor_salaries_url, params: { instructor_salary: { date_from: @instructor_salary.date_from, instructor_id: @instructor_salary.instructor_id, salary: @instructor_salary.salary } }
    end

    assert_redirected_to instructor_salary_url(InstructorSalary.last)
  end

  test "should show instructor_salary" do
    get instructor_salary_url(@instructor_salary)
    assert_response :success
  end

  test "should get edit" do
    get edit_instructor_salary_url(@instructor_salary)
    assert_response :success
  end

  test "should update instructor_salary" do
    patch instructor_salary_url(@instructor_salary), params: { instructor_salary: { date_from: @instructor_salary.date_from, instructor_id: @instructor_salary.instructor_id, salary: @instructor_salary.salary } }
    assert_redirected_to instructor_salary_url(@instructor_salary)
  end

  test "should destroy instructor_salary" do
    assert_difference('InstructorSalary.count', -1) do
      delete instructor_salary_url(@instructor_salary)
    end

    assert_redirected_to instructor_salaries_url
  end
end
