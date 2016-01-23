namespace :get_category do

  desc "get category"
  task :get_from_yahoo => :environment do

    YahooCategory.get_category_start

  end

  desc "convert category to tag"
  task :convert_yahoo_category_to_tag => :environment do
    root_categories = YahooCategory.where(tagged_depth: 100, is_default_tag: true, parent_id: nil)

    root_categories.each do |c|
      YahooCategory.convert_to_tag(c)
    end
  end

end
