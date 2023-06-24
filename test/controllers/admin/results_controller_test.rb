# require "test_helper"

# class Admin::ResultsControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @admin_result = admin_results(:one)
#   end

#   test "should get index" do
#     get admin_results_url
#     assert_response :success
#   end

#   test "should get new" do
#     get new_admin_result_url
#     assert_response :success
#   end

#   test "should create admin_result" do
#     assert_difference('Admin::Result.count') do
#       post admin_results_url, params: { admin_result: { date: @admin_result.date, references: @admin_result.references, score: @admin_result.score } }
#     end

#     assert_redirected_to admin_result_url(Admin::Result.last)
#   end

#   test "should show admin_result" do
#     get admin_result_url(@admin_result)
#     assert_response :success
#   end

#   test "should get edit" do
#     get edit_admin_result_url(@admin_result)
#     assert_response :success
#   end

#   test "should update admin_result" do
#     patch admin_result_url(@admin_result), params: { admin_result: { date: @admin_result.date, references: @admin_result.references, score: @admin_result.score } }
#     assert_redirected_to admin_result_url(@admin_result)
#   end

#   test "should destroy admin_result" do
#     assert_difference('Admin::Result.count', -1) do
#       delete admin_result_url(@admin_result)
#     end

#     assert_redirected_to admin_results_url
#   end
# end
