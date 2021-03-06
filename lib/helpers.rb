module Gitlog
  module Helpers
    def h(input)
      return input.nil? ? "" : CGI.escapeHTML("#{input}")
    end

    def image?(path)
      ['.png', '.jpg', '.jpeg', '.gif'].include?(File.extname(path))
    end

    def repo_link_to repo, name, opts={}

      if opts[:commit]
        commit = "/#{CGI.escape opts.delete(:commit)}"
      end

      if opts[:page]
        page = "/#{opts.delete(:page)}"
      end

      if repo.respond_to?("name")
        repo = repo.name
      end

      if opts[:path]
        path = "/#{opts.delete(:path)}"
      end

      %(<a href="/repo/#{repo}#{page}#{commit}#{path}" #{opts.inject(""){|m, (k,v)| m+="#{k}=\"#{v}\" " }}>#{name}</a>)
    end

    def blob_img_tag(commit, path)
      return '<img src="/raw/blob/'+ commit +'/'+path+'" alt="'+commit+'">'
    end

    def breadcrumb_path(repo, commit, path)

      path = path.split("/")
      path = path.select{|p| p != ""}

      link = Array.new

      last = path.pop

      if /[a-f0-9]{40}/ =~ commit
        commit_short = commit[0..6]
      else
        commit_short = commit
      end

      link << '<li class="active">'+last+'</li>' if last

      while path.size > 0
        target = path.pop
        if path.length > 0
          base = path.join("/")+"/"+target
        else
          base = target
        end
        link << '<li><a href="/repo/'+repo+'/tree/'+ commit + '/'+ base +'">'+target+'</a><span class="divider">/</span></li>'
      end

      if commit
        link << '<li><a href="/repo/'+repo+'/tree/'+ commit +'">'+commit_short+'</a><span class="divider">/</span></li>'
      end

      return '<ul class="breadcrumb">'+link.reverse.join("")+'</ul>'
    end

    def colorize_diff(diff)
      diff = PrettyDiff::Diff.new(diff)
      return diff.to_html
    end

    def tracker_ticket_url(repo, message)
      config = Gitlog::Config.new
      tracker = config.tracker_ticket_url(repo)
      if tracker
        message.gsub!(/#(\d+)/, '<a href="'+tracker+'\1">#\1</a>')
      end
      return message
    end

    def gravatar(email, size="200")
      return "https://secure.gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=" + size
    end

    def commit_time(time)
      time.strftime("%d %B, %Y")
    end

    # @todo: Make readable
    def commits_list(repo, commits)
      data = ""
      last_date = nil
      data << '<table class="table table-striped table-bordered commits">'
      commits.each do |commit|
        if last_date && last_date.strftime("%Y-%m-%d") != commit.date.strftime("%Y-%m-%d")
          data << '</table>'
          data << '<table class="table table-striped table-bordered commits">'
        end
        if last_date.nil? || last_date.strftime("%Y-%m-%d") != commit.date.strftime("%Y-%m-%d")
          #data << '</table><table class="table table-striped table-bordered commits">'
          data << '<tr class="date_separator">'
          data << '<td colspan="3" class="commit-date">' + commit.date.strftime("%Y-%m-%d") + '</td>'
          data << '</tr>'
        end
        data << '<tr class="commit">'
        data << '<td width="36px"><img src="' + gravatar(commit.author.email, "36x36") +'"></td>'
        data << '<td><span class="message-short"><a href="/repo/'+repo+'/commit/'+commit.id+'">' + h(commit.short_message) + '</a>'
        data << '&nbsp;<a href="#" class="btn btn-mini">More</a>' if commit.message.split("\n").count > 2
        data << '</span>'
        data << '<span class="message"><pre>' + tracker_ticket_url(repo, h(commit.message.split("\n")[2..-1].join("\n"))) + '</pre></span>' if commit.message.split("\n").count > 2
        data << '<small class="light"><span class="author-name">' + commit.author.name + '</span> authored <span class="date">' + commit_time( commit.authored_date ) + '</span></small>'
        data << '</br><small class="light committer">&#8618; <span class="committer-name">' + commit.committer.name + '</span> committed <span class="date">' + commit_time( commit.committed_date ) + '</span></small>' if commit.author.email != commit.committer.email
        data << '</td>'
        data << '<td width="110px" class="link"><div class="btn-group pull-right">'
        data << '<a href="/repo/'+repo+'/commit/'+commit.id+'" class="btn btn-mono btn-info">' + commit.id[0..4] + '</a>'
        data << '<button class="btn btn-info dropdown-toggle" data-toggle="dropdown"><span class="caret"></span></button>'
        data << '<ul class="dropdown-menu">'
        data << '<li><a href="/repo/'+repo+'/commit/'+commit.id+'">View commit</a></li>'
        data << '<li><a href="/repo/'+repo+'/tree/'+commit.id+'">Browse code</a></li>'
        data << '</ul>'
        data << '</td>'
        data << '</tr>'
        last_date = commit.date
      end
      data << '</table>'
      return data
    end

  end
end
