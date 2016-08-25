namespace :tag_migration do

  desc "add tag migration history"
  task :add_tag_migration_history => :environment do

    last_migration = TagMigrationHistory.last
    min = last_migration.tag_changed_at rescue Time.new(2016,1,1)
    changed_tags = ActsAsTaggableOn::Tag.where(is_default_tag: true)
      .where("updated_at > ?", min)
      #.where("updated_at > ?", last_migration.tag_changed_at)

    added = []
    updated = []
    deleted = []

    last_changed_at = changed_tags.first.updated_at

    changed_tags.each do |tag|
      change_from = (tag.updated_at - tag.created_at)
      if(tag.is_deleted)
        deleted << tag.id
      elsif change_from < 60
        added << tag.id
      else
        updated << tag.id
      end

      if tag.updated_at > last_changed_at
        last_changed_at = tag.updated_at
      end
    end

    TagMigrationHistory.create(
      added_tags: added,
      updated_tags: updated,
      deleted_tags: deleted,
      tag_changed_at: last_changed_at
    )

  end

end
