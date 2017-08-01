require 'json'
load 'deploy'
require 'capistrano-docker'
require 'capistrano-sauron'
require 'capistrano-jenkins'

set :application, "youtube-stream-analytics"
set :scm, :none
set :branch, ENV["BRANCH"] || 'master'
set :user,"handwire"
ssh_options[:forward_agent] = true
set :use_sudo, true

set :docker_repo_name,"voxmedia/#{application}"

set :sauron_api,"docker1.voxops.net:7000"
set :sauron_container_port, 3000
set :sauron_container_hostnames, ["#{application}.rnd.voxops.net","#{application}.rnd.voxmedia.com"]
set :sauron_container_healthcheck, "GET /ping"

task :production do
  set :jenkins_host, "docker-builder.voxops.net"
  set :jenkins_job, "docker-deployer"
  set :target_environment, "production"

  set :docker_args, "-v /root/youtube-stream-analytics.env:/app/.env"
  role :app, "docker1.voxops.net", :primary => true
end


namespace "docker" do
  # e.g.to run a db migration, first deploy the app then run
  # bundle exec cap production docker:invoke CMD="bundle exec rake db:migrate"
  # e.g. to run a one-off script run
  # bundle exec cap production docker:invoke CMD="bundle exec ruby import.rb -c bidder -f 2016-11-01 -t 2017-01-26"
  desc "run a one-off command on the docker container"
  task :invoke do
    cmd = ENV["CMD"]
    sudo "docker run --rm=true #{docker_args} #{docker_repo_name} #{cmd}"
  end

  task :logs do
    sudo "docker logs --tail=10 --follow `sudo docker ps | grep #{application} | awk \'{print $1}\'`"
  end
end
