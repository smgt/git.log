require "sinatra/base"
#require "sinatra/respond_to"
require 'digest/md5'
require "cgi"
require "grit"
require "albino"
require "yaml"

class GitLog < Sinatra::Base

  if File.exists?("config.yaml")
    @@config = YAML.load_file("config.yaml")
    @@repo = Grit::Repo.new("/Users/simon/Development/Flattr/flattr.git")
  else
    puts "Not config.yaml present.."
    exit 0
  end

  helpers do

    def h(input)
      return CGI.escapeHTML(input)
    end

    def colorize(diff)
      diff = Albino.new(diff, :diff, :html)
      return diff.colorize({:O => "tabsize=4,linenos=inline,lineanchors=line"})
    end

    def gravatar(email, size="200")
      return "http://www.gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=" + size
    end

  end

  # Redirect to HEAD
  get "/" do
    redirect to("/branch/HEAD")
  end

  # List branches
  get "/branch" do
    branches = @@repo.branches
    erb :branches, :locals => {:branches => branches}
  end

  # Show latest commits for a branch
  get "/branch/*" do
    commits = @@repo.commits(params[:splat].first, 50)
    erb :branch, :locals => {:repo => @@repo, :commits => commits, :branch => params[:splat].first}
  end

  # Show commit
  get "/commit/:sha" do
    commit = @@repo.commits(params[:sha])
    erb :commit, :locals => {:commit => commit}
  end

  # Show file
  get "/tree/:path" do
    return params[:path]
  end

  # Show commits by author
  get "/author/:email" do
    return params[:email]
  end

end
