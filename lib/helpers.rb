module Gitlog
  module Helpers
    def h(input)
      return input.nil? ? "" : CGI.escapeHTML("#{input}")
    end

    def image?(path)
      ['.png', '.jpg', '.jpeg', '.gif'].include?(File.extname(path))
    end

    def blob_img_tag(commit, path)
      return '<img src="/raw/blob/'+ commit +'/'+path+'" alt="'+commit+'">'
    end

    def breadcrumb_path(repo, commit, path)
      path = path.split("/")
      link = Array.new
      last = path.pop
      link << last

      while path.size > 0
        link << '<a href="/repo/'+repo+'/tree/'+ commit + '/'+path.join("/")+'">'+path.pop+'</a>'
      end

      if /[a-f0-9]{40}/ =~ commit
        commit_short = commit[0..6]
      else
        commit_short = commit
      end
      if commit
        link << '<a href="/repo/'+repo+'/tree/'+ commit +'">'+commit_short+'</a>'
      end
      return link.reverse.join(" / ")
    end

    def colorize_diff(diff)
      diff = PrettyDiff::Diff.new(diff)
      return diff.to_html
    end

    def gravatar(email, size="200")
      return "http://www.gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=" + size
    end

    def commits_list(repo, commits)
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
        data << '<td><a href="/repo/' + repo + '/commit/' + commit.id + '">' + commit.id[0..4] + '</a></td>'
        data << '</tr>'
        last_date = commit.date
      end
      data << '</table>'
      return data
    end

  end
end
