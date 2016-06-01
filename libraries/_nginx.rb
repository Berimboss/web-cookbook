module Nginx
  class Installer
    def default_repo
      nil
    end
    def default_branch
      nil
    end
    def default_path
      nil
    end
    def default_grp
      nil
    end
    def default_usr
      nil
    end
    def sources
      [
        {:type => 'git', :location => 'https://github.com/nginx/nginx.git'}
      ]
    end
    def git_clone(repo, branch, path, grp='root', usr='root')
      git path do
        checkout_branch branch
        repository repo
        group grp
        user usr
      end
    end
    def install(method)
      case method
      when :git
        self.install_git
      end
    end
    def install_git
      nil
    end
  end
end
