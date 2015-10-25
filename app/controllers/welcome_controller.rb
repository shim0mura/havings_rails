class WelcomeController < ApplicationController

  before_action :authenticate_user!

  def index
    @current_user = current_user
  end

  def home
    @current_user = current_user
    line_chart
  end


  def line_chart
    data_table = GoogleVisualr::DataTable.new
    data_table.new_column('string', 'Year')
    data_table.new_column('number', 'Sales')
    data_table.new_column('number', 'ああああ')
    data_table.add_rows(3)
    data_table.set_cell(0, 0, '2004')
    data_table.set_cell(0, 1, 1000)
    data_table.set_cell(0, 2, 400)
    data_table.set_cell(1, 0, '2005')
    data_table.set_cell(1, 1, 1170)
    data_table.set_cell(1, 2, nil)
    data_table.set_cell(2, 0, '2007')
    data_table.set_cell(2, 1, 860)
    data_table.set_cell(2, 2, 580)
    # data_table.set_cell(3, 0, '2007')
    # data_table.set_cell(3, 1, 1030)
    # data_table.set_cell(3, 2, 540)

    options = {
      height: 240,
      title: 'Company Performance',
      legend: 'bottom',
      interpolateNulls: true
    }
    @chart = GoogleVisualr::Interactive::LineChart.new(data_table, options)
  end

end
