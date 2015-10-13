# http://qiita.com/zaru/items/8385fdddbd1be25fe370
Sidekiq.configure_server do |config|
    config.redis = { url: 'redis://localhost:6379', namespace: 'sidekiq' }
end
Sidekiq.configure_client do |config|
    config.redis = { url: 'redis://localhost:6379', namespace: 'sidekiq' }
end
