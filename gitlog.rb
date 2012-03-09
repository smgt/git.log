require "charlock_holmes"
require "sinatra/base"
require "sinatra/namespace"
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

  register Sinatra::Namespace

  helpers do
    include Gitlog::Helpers
  end

  configure :development do
    enable :logging
  end

  error 404 do
    "Nothing FOUND"
  end

  before do
    @config = Gitlog::Config.new
  end

  namespace "/repo/:repo" do

    # Fetch the repo from the path
    before do
      @repo = Gitlog::Repository.new params[:repo]
      if @repo.repository.nil?
        halt 404, "No repository by that name"
      end
    end

    get "/compare/:target" do
      targets = params[:target].split("...")
      commits = @repo.commits_between(targets.first, targets.last).reverse
      erb :compare, :locals => {
        :repo => @repo,
        :commits => commits,
        :branch => @branch,
        :subnav => :commits,
        :page_title=>"Comparing commits"
      }
    end

    # List branches
    get "/branches" do
      branches = @repo.branches
      erb :branches, :locals => {
        :repo => @repo,
        :branch => @branch,
        :branches => branches,
        :subnav => :branches,
        :page_title => "Branches"
      }
    end

    get "/commits/:branch/*" do
      commits = @repo.log(params[:branch], params[:splat].last)
      erb :history, :locals => {
        :repo => @repo,
        :commits => commits,
        :branch => params[:branch],
        :path => params[:splat].last,
        :subnav => :commits,
        :page_title => "Commits"
      }
    end

    # Redirect to master
    get "/commits" do
      branch = "master"
      page = params[:page] || 0
      commits = @repo.commits(branch, 100, (page.to_i * 100))
      erb :commits, :locals => {
        :repo => @repo,
        :commits => commits,
        :branch => branch,
        :subnav => :commits,
        :page => page,
        :page_title => "Commit history"
      }
    end

    # Show latest commits for a branch
    get "/commits/:branch" do
      page = params[:page] || 0
      commits = @repo.commits(params[:branch], 100, (page.to_i * 100))
      erb :commits, :locals => {
        :repo => @repo,
        :commits => commits,
        :branch => params[:branch],
        :subnav => :commits,
        :page => page,
        :page_title => "Commit history"
      }
    end

    # Show commit
    get "/commit/:sha" do
      commit = @repo.commits(params[:sha])
      erb :commit, :locals => {
        :branch => 'master',
        :commit => commit.first,
        :repo => @repo,
        :subnav => :commits
      }
    end

    get "/tree" do
      redirect to "/repo/#{params[:repo]}/tree/master"
    end

    # Show the tree for a certain target
    get "/tree/:branch" do
      tree = @repo.tree(params[:branch])
      erb :tree, :locals => {
        :tree => tree,
        :path => "/",
        :branch => params[:branch],
        :repo => @repo,
        :subnav => :files,
        :page_title => "Files"
      }
    end

    # Show tree from HEAD of a branch
    get "/tree/:branch/*" do
      tree = @repo.tree(params[:branch])
      if params[:splat].first
        tree = tree / params[:splat].first
        path = "/" + params[:splat].first + "/"
      end
      erb :tree, :locals => {
        :tree => tree,
        :path => path,
        :branch => params[:branch],
        :repo => @repo,
        :subnav => :files,
        :page_title => "Files"
      }
    end

    # Show a blob
    get "/blob/:commit/*" do
      tree = @repo.tree(params[:commit])
      blob = tree / params[:splat].first
      erb :blob, :locals => {
        :blob => blob,
        :path => params[:splat].first,
        :tree => tree,
        :commit_id => params[:commit],
        :branch => params[:commit],
        :repo => @repo,
        :subnav => :files,
        :page_title => "Files"
      }
    end

    get "/raw/blob/:commit/*" do
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

  end #End namespace /repo/:repo

  # Well...
  get "/blame/:branch/:commit/*" do
    #blame = Grit::Blame.new(params[:branch], params[:splat].first, params[:commit])
    halt 403, "Blame is not an option!"
  end


  get "/about" do
    erb :about
  end

  get "/" do
    repositories = Gitlog::Config.new.repositories
    erb :index, :locals => {:repos => repositories}
  end

end
