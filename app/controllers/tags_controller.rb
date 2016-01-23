class TagsController < ApplicationController

  before_action :authenticate_user!

  def tag_migration_version
    latest_histroy = TagMigrationHistory.last
    @latest_migration = latest_histroy.id
  end

  def default_tag_migration
    tags = ActsAsTaggableOn::Tag.where(
      is_default_tag: true,
      is_deleted: false
    )

    @migrations = []
    @migrations << {
      updated_tags: tags,
      migration_version: TagMigrationHistory.last.id
    }
  end

  def tag_migration
    histories = TagMigrationHistory.where("id > ?", params[:migration_id])
    @migrations = []
    histories.each do |h|
      
      keys = [
        :added_tags,
        :updated_tags,
        :deleted_tags
      ]

      updated_tags = []

      keys.each do |k|
        tag_ids = h.send(k)
        next if tag_ids.nil?
        tag_ids = JSON.parse(tag_ids)
        updated_tags.concat(ActsAsTaggableOn::Tag.where(
          is_default_tag: true,
          id: tag_ids
        ))
      end

      @migrations << {
        updated_tags: updated_tags,
        migration_version: h.id
      }
      pp @migrations
    end
  end

end
