require "rake"
require "yaml"
require "erb"

desc "Apply the Ansible configurations"
task :deploy do
  sh("ansible-playbook",
     "--inventory-file", "hosts",
     "ansible/playbook.yml")
end

class RepositoryListUpdater
  include ERB::Util

  def initialize
  end

  def update
    config_path = "ansible/files/home/mailer/web-hooks-receiver/config.yaml"
    config = YAML.load(File.read(config_path))
    owners = config["domains"]["github.com"]["owners"]

    html_path = "ansible/files/apache/www/index.html"
    html = File.read(html_path)
    html = replace_table(html, owners)

    File.open(html_path, "w") do |html_file|
      html_file.puts(html)
    end
  end

  private
  def replace_table(html, owners)
    html.gsub(/^\s*<table id="repository-list">.+?<\/table>/m) do
      table = <<-HEADER
      <table id="repository-list">
        <thead>
          <tr>
            <th>Owner</th>
            <th>Repository</th>
            <th>Mailing list</th>
          </tr>
        </thead>
        <tbody>
      HEADER
      owners.each do |owner, owner_configs|
        table << format_row(owner, :all, owner_configs["to"])
        repositories = owner_configs["repositories"] || {}
        repositories.each do |repository, repository_configs|
          table << format_row(owner, repository, repository_configs["to"])
        end
      end
      table << <<-FOOTER.chomp
        </tbody>
      </table>
      FOOTER
    end
  end

  def format_row(owner, repository, to)
    to = to.first if to.is_a?(Array)
    return "" if to.nil?

    if repository == :all
      repository_column = "(all)"
    else
      repository_column =
        "<a href=\"#{repository_url(owner, repository)}\">#{h(repository)}</a>"
    end
    <<-ROW
          <tr>
            <td><a href="#{owner_url(owner)}">#{h(owner)}</a></td>
            <td>#{repository_column}</td>
            <td>#{h(to)}</td>
          </tr>
    ROW
  end

  def owner_url(owner)
    "https://github.com/#{h(owner)}/"
  end

  def repository_url(owner, repository)
    "#{owner_url(owner)}#{h(repository)}/"
  end
end

namespace :repository do
  namespace :list do
    desc "Update repository list"
    task :update do
      updater = RepositoryListUpdater.new
      updater.update
    end
  end
end
