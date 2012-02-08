require "charlock_holmes"
require "sinatra/base"
require 'digest/md5'
require "cgi"
require "grit"
require "yaml"
require "linguist"
require "pretty_diff"
require "fileutils"
require "pygments.rb"

require "lib/config"
require "lib/helpers"
require "lib/repository"

class Grit::Blob
  include Linguist::BlobHelper
end

class GitLog < Sinatra::Base

  helpers do
    include Gitlog::Helpers
  end

  before "/repo/:repo/*" do
    @repo = Gitlog::Repository.new params[:repo]
    if @repo.repository.nil?
      halt 404, "No repository by that name"
    end
  end

  get "/" do
    repositories = Gitlog::Config.new.repositories
    erb :index2, :locals => {:repos => repositories}
  end

  # List branches
  get "/repo/:repo/branches" do
    branches = @repo.branches
    erb :branches, :locals => {:branches => branches, :repo => @repo}
  end

  get "/repo/:repo/commits/:branch/*" do
    commits = @repo.log(params[:branch], params[:splat].last)
    erb :history, :locals => {:repo => @repo, :commits => commits, :branch => params[:branch], :path => params[:splat].last}
  end

  # Redirect to master
  get "/repo/:repo/commits" do
    redirect to "/repo/#{params[:repo]}/commits/master"
  end

  # Show latest commits for a branch
  get "/repo/:repo/commits/:branch" do
    commits = @repo.commits(params[:branch], 50)
    erb :commits, :locals => {:repo => @repo, :commits => commits, :branch => params[:branch]}
  end

  # Show commit
  get "/repo/:repo/commit/:sha" do
    commit = @repo.commits(params[:sha])
    erb :commit, :locals => {:commit => commit.first, :repo => @repo}
  end

  get "/repo/:repo/tree" do
    redirect to "/repo/#{params[:repo]}/tree/master"
  end

  # Show the tree for a certain target
  get "/repo/:repo/tree/:branch" do
    tree = @repo.tree(params[:branch])
    erb :tree, :locals => {:tree => tree, :path => "", :branch => params[:branch], :repo => @repo}
  end

  # Show tree from HEAD of a branch
  get "/repo/:repo/tree/:branch/*" do
    tree = @repo.tree(params[:branch])
    if params[:splat].first
      tree = tree / params[:splat].first
    end
    erb :tree, :locals => {:tree => tree, :path => params[:splat].first, :branch => params[:branch], :repo => @repo}
  end

  # Show a blob
  get "/repo/:repo/blob/:commit/*" do
    tree = @repo.tree(params[:commit])
    blob = tree / params[:splat].first
    erb :blob, :locals => {:blob => blob, :path => params[:splat].first, :tree => tree, :commit_id => params[:commit], :repo => @repo}
  end

  get "/repo/:repo/raw/blob/:commit/*" do
    config = Gitlog::Config.new
    cache_path = "#{config["cache"]["blob"]}#{params[:repo]}/"

    if File.exists?("#{cache_path}#{params[:commit]}/#{params[:splat].first}")
      send_file("#{cache_path}#{params[:commit]}/#{params[:splat].first}")
    else
      tree = @@repo.tree(params[:commit])
      blob = tree / params[:splat].first
      path = File.dirname(params[:splat].first)
      file = File.basename(params[:splat].first)
      if blob
        FileUtils.mkdir_p("#{cache_path}#{params[:commit]}/#{path}")
        fh = File.new("#{cache_path}#{params[:commit]}/#{path}/#{file}", "w")
        fh.write(blob.data)
        fh.close
      end
      return send_file("#{cache_path}#{params[:commit]}/#{path}/#{file}")
    end
  end

  # Well...
  get "/blame/:branch/:commit/*" do
    #blame = Grit::Blame.new(params[:branch], params[:splat].first, params[:commit])
    halt 403, "Blame is not an option!"
  end

  # Show commits by author
  get "/author/:email" do
    return params[:email]
  end

end
