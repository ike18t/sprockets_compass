class TestController < ApplicationController
  def index
    render :action => :test_view
  end

  def test_view

  end
end
