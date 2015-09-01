class ItemList < ActiveRecord::Base
  belongs_to :item_list_in, class_name: Item, foreign_key: :list_id
  belongs_to :item_list_from, class_name: Item, foreign_key: :item_id
end
