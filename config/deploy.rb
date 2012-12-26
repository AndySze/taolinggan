set :application, "taolinggan"
set :domain, "42.121.104.100"
set :user, 'root'

# adjust if you are using RVM, remove if you are not
set :rvm_ruby_string, 'ruby-1.9.3-p327-falcon'
set :rvm_type, :system  # Copy the exact line. I really mean :system here
require "rvm/capistrano"

set :repository,  "git://github.com/AndySze/taolinggan.git"
set :deploy_to, "/home/andy/#{application}"


role :web, domain # Your HTTP server, Apache/etc
role :app, domain # This may be the same as your `Web` server
role :db, domain , :primary => true # This is where Rails migrations will run

set :deploy_via, :remote_cache
set :scm, 'git'
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :branch, 'master'
set :scm_verbose, true
set :use_sudo, false
set :rails_env, :production

set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

namespace :deploy do

  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && #{try_sudo} unicorn -c #{unicorn_config} -E #{rails_env} -D"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill `cat #{unicorn_pid}`"
  end
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end

  desc "things I need to do after deploy:setup"
  task :setup_config, :roles => :app do
    run "#{try_sudo} ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    run "mkdir -p #{shared_path}/config"
    put File.read("config/database.yml.mysql"), "#{shared_path}/config/database.yml"
    puts "Now edit the config files in #{shared_path}. create db"
  end
  after "deploy:setup", "deploy:setup_config"

  task :symlink_config, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "deploy:symlink_config"

  desc "reload the database with seed data"
  task :seed do
    run "cd #{current_path}; rake db:seed RAILS_ENV=#{rails_env}"
  end

  desc "install the necessary prerequisites"
  task :bundle_install, :roles => :app do
    run "cd #{current_path} && bundle install --without development test"
  end


end


# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
