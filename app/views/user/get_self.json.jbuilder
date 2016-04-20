json.extract! @user, :id, :name, :description
json.image @user.thumbnail
json.count @home_list.count

json.following_count @user.following.count
json.follower_count @user.followed.count
json.dump_items_count @user.items.dump.count
json.image_favorites_count @user.image_favorites.count
json.favorites_count @user.favorites.count

json.background_image @background_image
