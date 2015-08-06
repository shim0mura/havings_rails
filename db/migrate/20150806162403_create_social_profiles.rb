class CreateSocialProfiles < ActiveRecord::Migration
  def change
    create_table :social_profiles do |t|
      t.references :user, index: true
      t.string :provider, limit: 30
      t.string :uid, limit: 160
      t.string :access_token
      t.string :token_secret
      t.string :name
      t.string :nickname
      t.string :email
      t.string :url
      t.string :image_url
      t.string :description
      t.text :other
      t.text :credentials
      t.text :raw_info

      t.timestamps null: false
    end

    add_index :social_profiles, [:provider, :uid], unique: true
  end
end

