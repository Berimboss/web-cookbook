namespace :publishing do
  cookbook_path = ENV['RAKE_COOKBOOK_PATH']
  cookbook_name = ::File.read('NAME').strip
  task :git_update do
    system <<-EOH
    git add -f *
    git commit -a -m "updated blindly from rake to version #{::File.read('VERSION').strip}"
    git push origin #{`git rev-parse --abbrev-ref HEAD`}
    EOH
  end
  task :up_minor_version do
    stripped = ::File.read('VERSION').strip
    new_minor = stripped.split('.')[-1].to_i
    new_minor += 1
    new_minor_string = new_minor.to_s
    new_minor = new_minor_string.to_s
    new_version = stripped.split('.')[0..-2]
    new_version << new_minor_string
    version = new_version.join('.')
    match = stripped
    replace = version
    file = 'VERSION'
    system 'rm -rf VERSION'
    ::File.write('VERSION', version.strip)
  end
  task :sync_berkshelf do
    system 'berks install && berks update'
  end
  task :supermarket do
    system <<-EOH
    knife cookbook site share #{cookbook_name} "Other" -o #{cookbook_path}
    EOH
  end
  task :publish => [:up_minor_version, :git_update, :sync_berkshelf, :supermarket]
end
task :default => 'publishing:publish'
