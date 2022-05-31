require 'test_helper'
class ApplicationHelperTest < ActionView::TestCase
  def setup
  end

  test 'months_logged method' do
    assert_equal ["Aug 2021", "Sep 2021", "Oct 2021", "Nov 2021", "Dec 2021", "Jan 2022", "Feb 2022", "Mar 2022", "Apr 2022"], months_logged
  end

  test 'month_period method' do
    t1=DateTime.new(2022,3,1,10,30,0)
    t2=DateTime.new(2022,3,31,19,30,0)
    t3=DateTime.new(2022,4,1,0,0,0)
    t4=DateTime.new(2022,2,28,23,59,59)
    assert month_period('March 2022').cover? t1
    assert month_period('March 2022').cover? t2
    refute month_period('March 2022').cover? t3
    refute month_period('March 2022').cover? t4
  end
end
