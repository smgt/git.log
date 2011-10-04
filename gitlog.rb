$: << './lib/linguist/lib'
require "charlock_holmes"
require "sinatra/base"
require 'digest/md5'
require "cgi"
require "grit"
require "albino"
require "yaml"
require "./lib/linguist/lib/linguist/blob_helper"
require "pretty_diff"

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
      diff = PrettyDiff::Diff.new(diff)
      return diff.to_html
    end

    def gravatar(email, size="200")
      return "http://www.gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=" + size
    end

    def commits_list(commits)
      data = ""
      data += '<table class="commits">'
      last_date = nil
      commits.each do |commit|
        if last_date.nil? || last_date.strftime("%Y-%m-%d") != commit.date.strftime("%Y-%m-%d") 
          data << '<tr class="date_separator">'
          data << '<td colspan="3">' + commit.date.strftime("%Y-%m-%d") + '</td>'
          data << '</tr>'
        end
        data << '<tr class="commit">'
        data << '<td><img src="' + gravatar(commit.author.email, "36x36") +'"></td>'
        data << '<td>' + h(commit.message.split("\n").first) + '<br><span class="info">Authored by <span class="author">' + commit.author.name + '</span> at <span class="date">' + commit.date.strftime("%Y-%m-%d %H:%M:%S") + '</span></span></td>'
        data << '<td><a href="/commit/' + commit.id + '">' + commit.id[0..4] + '</a></td>'
        data << '</tr>'
        last_date = commit.date
      end
      data << '</table>'
      return data
    end

  end

  # Redirect to HEAD
  get "/" do
    redirect to("/commits/master")
  end

  # List branches
  get "/branches" do
    branches = @@repo.branches
    erb :branches, :locals => {:branches => branches}
  end

  get %r{/commits/(.+)/(.+)$} do
    commits = @@repo.log(params[:captures].first, params[:captures].last)
    erb :history, :locals => {:repo => @@repo, :commits => commits, :branch => params[:captures].first, :file => params[:captures].last}
  end

  # Show latest commits for a branch
  get "/commits/:branch" do
    commits = @@repo.commits(params[:branch], 50)
    erb :commits, :locals => {:repo => @@repo, :commits => commits, :branch => params[:branch]}
  end

  # Show commit
  get "/commit/:sha" do
    commit = @@repo.commits(params[:sha])
    erb :commit, :locals => {:commit => commit.first}
  end

  # Show the tree for a certain branch
  get "/tree/:branch" do
    tree = @@repo.tree(params[:branch])
    erb :tree, :locals => {:tree => tree, :path => "", :branch => params[:branch]} 
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
    if params[:splat].first
      tree = tree / params[:splat].first
    end
    erb :tree, :locals => {:tree => tree, :path => params[:splat].first, :branch => params[:branch]}
  end

  # Show a blob
  get "/blob/:branch/*" do
    tree = @@repo.tree(params[:branch])
    blob = tree / params[:splat].first 
    erb :blob, :locals => {:blob => blob, :path => params[:splat].first, :tree => tree}
  end

  # Well...
  get "/blame/:branch/:commit/*" do
    #blame = Grit::Blame.new(params[:branch], params[:splat].first, params[:commit])
    return false
  end

  # Show commits by author
  get "/author/:email" do
    return params[:email]
  end

end
