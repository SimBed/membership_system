# require "test_helper"

# class Admin::LeaguesControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @admin_league = admin_leagues(:one)
#   end

#   test "should get index" do
#     get admin_leagues_url
#     assert_response :success
#   end

#   test "should get new" do
#     get new_admin_league_url
#     assert_response :success
#   end

#   test "should create admin_league" do
#     assert_difference('Admin::League.count') do
#       post admin_leagues_url, params: { admin_league: { metric: @admin_league.metric, name: @admin_league.name } }
#     end

#     assert_redirected_to admin_league_url(Admin::League.last)
#   end

#   test "should show admin_league" do
#     get admin_league_url(@admin_league)
#     assert_response :success
#   end

#   test "should get edit" do
#     get edit_admin_league_url(@admin_league)
#     assert_response :success
#   end

#   test "should update admin_league" do
#     patch admin_league_url(@admin_league), params: { admin_league: { metric: @admin_league.metric, name: @admin_league.name } }
#     assert_redirected_to admin_league_url(@admin_league)
#   end

#   test "should destroy admin_league" do
#     assert_difference('Admin::League.count', -1) do
#       delete admin_league_url(@admin_league)
#     end

#     assert_redirected_to admin_leagues_url
#   end
# end
