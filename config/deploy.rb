# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'havings'
# repository for bitbucket
set :repo_url, 'ssh://git@bitbucket.org/shim0mura/havings_rails.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :user, "shim0mura"
set :group, "shim0mura"
set :runner, "shim0mura"

# Default value for :scm is :git
# set :scm, :git
set :conditionally_migrate, true

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, 'config/database.yml', 'config/secrets.yml'

# Default value for linked_dirs is []
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5
set :unicorn_pid, "#{shared_path}/tmp/pids/unicorn.pid"


set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.1.4'

set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :all # default value

namespace :deploy do

  desc 'Make rake run in container'
  task :map_rake do
    SSHKit.config.command_map[:rake] = "sudo docker run -rm rake"
  end
  before 'bundler:install', 'deploy:map_rake'

  desc "START server"
  task :start do
    on roles(:app) do 
      run "cd /home/shimomura/compose && docker-compose up"
      run "docker-compose up"
    end
  end

  desc "STOP server"
  task :stop do
    on roles(:app) do 
      run "kill `cat #{deploy_to}/tmp/pids/server.pid`"
    end
  end

  desc "RESTART server"
  task :restart do
    # run "kill -USR2 `cat #{deploy_to}/shared/pids/unicorn.pid`"
    # TODO: rescue関連のリスタート
    # run "cd #{current_path} && RAILS_ENV=development QUEUE='*' PIDFILE=#{current_path}/tmp/pids/resque_.pid VERBOSE=1 bundle exec rake environment resque:work"
    # 1.upto(worker.to_i) do |i|
    #   p "#{current_path}/tmp/pids/resque_#{i}.pid"
    #   if File.exists?("#{current_path}/tmp/pids/resque_#{i}.pid")
    #     run "kill -9 `#{current_path}/tmp/pids/resque_#{i}.pid"
    #     run "rm #{current_path}/tmp/pids/resque_#{i}.pid"
    #   end
    #   # run "cd #{current_path} && RAILS_ENV=development QUEUE='*' PIDFILE=#{current_path}/tmp/pids/resque_#{i}.pid VERBOSE=1 nohup bundle exec rake environment resque:work > log/nohup_#{i}.out 2>&1 < /dev/null &"
    # end
  end

  # desc "copy database.yml"
  # after "deploy:update_code", :roles => :app do
  #   run("cp ~/replace_files/database_#{rails_env}.yml #{release_path}/config/database.yml")
  # end

  # desc "bundle install"
  # after "deploy:update_code", :roles => :app do
  #   run "cd #{release_path} && bundle"
  # end

  # after 'deploy:update', 'deploy:migrate'

  desc 'upload important files'
  task :upload_config do
    on roles(:app) do |host|
      execute :mkdir, '-p', "#{shared_path}/config"
      upload!('config/database.yml',"#{shared_path}/config/database.yml")
      upload!('config/secrets.yml',"#{shared_path}/config/secrets.yml")
    end
  end
end
