# 本番以外だと使わない上に邪魔なので除外
# require "kakasi.so"
# include Kakasi

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


  desc "set yomi and roma of tag"
  task :tag_yomi => :environment do
    ActsAsTaggableOn::Tag.where(
      is_default_tag: true
    ).each do |tag|

      aa = tag.name
      a = kakasi("-JH -KH -o utf-8", aa.encode("EUC-JP"))
      a.force_encoding('UTF-8').encode('UTF-8')
      pp a
      pp a.encoding
      tag.yomi_jp = a
      b = kakasi("-Ja -Ka -Ha -o utf-8", aa.encode("EUC-JP"))
      b.force_encoding("UTF-8")
      b.gsub!("^", "-")
      pp b
      pp b.encoding
      tag.yomi_roma = b
      tag.save
    end

    # tag = ActsAsTaggableOn::Tag.where(is_default_tag: true).first
    # aa = tag.name
    # pp aa.encoding
    # a = kakasi("-JH -KH -o utf-8", aa.encode("EUC-JP"))
    # pp a
    # pp a.encoding
    # a.force_encoding('UTF-8').encode('UTF-8')
    # pp a
    # pp a.encoding
    # b = kakasi("-Ka -Ha -o utf-8", aa.encode("EUC-JP"))
    # pp b
    # pp b.encoding
    # b.force_encoding("UTF-8")
    # b.gsub!("^", "-")
    # pp b


  end

end
