namespace :chart do

  desc "set Item's classed_tag_id"
  task :set_classed_tag_id => :environment do

    Item.all.each do |i|
      chart_type, ancestor_tags = Chart.get_primary_category_ancestors(i.tags)
      ancestor_tags.each do |t|
        i.classed_tag_id = t.id if t.tag_type == Chart::TAG_TYPE_CATEGORY
        pp i
      end
      i.save
    end

  end

end
