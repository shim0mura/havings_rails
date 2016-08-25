# json.array! @migrations, :migration_version, :updated_tags

json.array! @migrations do |mig|
  json.migration_version mig[:migration_version]
  json.updated_tags mig[:updated_tags], :id, :name, :yomi_jp, :yomi_roma, :parent_id, :tag_type, :priority, :is_deleted
end

