$: << './lib/linguist/lib'
require "charlock_holmes"
require "sinatra/base"
require 'digest/md5'
require "cgi"
require "grit"
require "albino"
require "yaml"
require "./lib/linguist/lib/linguist/blob_helper"

class Grit::Blob 
  include Linguist::BlobHelper
end

class GitLog < Sinatra::Base

  if File.exists?("config.yaml")
    @@config = YAML.load_file("config.yaml")
    @@repo = Grit::Repo.new @@config["repository"]
  else
    puts "Not config.yaml present.."
    exit 0
  end

  helpers do

    def h(input)
      return CGI.escapeHTML(input)
    end

    def colorize_diff(diff)
      diff = Albino.new(diff, :diff, :html)
      return diff.colorize({:O => "tabsize=4,linenos=inline,lineanchors=line"})
    end

    def gravatar(email, size="200")
      return "http://www.gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=" + size
    end

  end

  # Redirect to HEAD
  get "/" do
    redirect to("/commits/HEAD")
  end

  # List branches
  get "/branches" do
    branches = @@repo.branches
    erb :branches, :locals => {:branches => branches}
  end

  # Show latest commits for a branch
  get "/commits/*" do
    commits = @@repo.commits(params[:splat].first, 50)
    erb :commits, :locals => {:repo => @@repo, :commits => commits, :branch => params[:splat].first}
  end

  # Show commit
  get "/commit/:sha" do
    commit = @@repo.commits(params[:sha])
    erb :commit, :locals => {:commit => commit.first}
  end

  # Show a tree based on sha
  get %r{/tree/([a-f0-9]{40})$} do
    sha = params[:captures].first
    tree = @@repo.tree(sha)
    erb :tree, :locals => {:tree => tree}
  end

  # Show tree from HEAD of a branch
  get "/tree/:branch/*" do
    tree = @@repo.tree(params[:branch])
    tree = tree / params[:splat].first
    erb :tree, :locals => {:tree => tree, :path => params[:splat].first}
  end

  # Show a blob
  get "/blob/:branch/*" do
    tree = @@repo.tree(params[:branch])
    blob = tree / params[:splat].first 
    erb :blob, :locals => {:blob => blob}
  end

  # Show commits by author
  get "/author/:email" do
    return params[:email]
  end

end
