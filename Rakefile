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
    config_path = "ansible/files/home/mailer/webhook-mailer/config.yaml"
    config = YAML.safe_load(File.read(config_path),
                            aliases: true)

    html_path = "ansible/files/var/www/html/index.html"
    html = File.read(html_path)
    html = replace_table(html, "gitlab.com", config)
    html = replace_table(html, "github.com", config)

    File.open(html_path, "w") do |html_file|
      html_file.puts(html)
    end
  end

  private
  def replace_table(html, fqdn, config)
    owners = config["domains"][fqdn]["owners"]
    host = fqdn.split(".").first
    case fqdn
    when "github.com"
      owner_label = "Owner"
    else
      owner_label = "Group"
    end
    id_pattern = "#{Regexp.escape(host)}-repository-list"
    html.gsub(/^\s*<table id="#{id_pattern}">.+?<\/table>/m) do
      table = <<-HEADER
        <table id="#{host}-repository-list">
          <thead>
            <tr>
              <th>#{owner_label}</th>
              <th>Repository</th>
              <th>Mailing list</th>
            </tr>
          </thead>
          <tbody>
      HEADER
      owners.each do |owner, owner_configs|
        table << format_row(fqdn, owner, :all, owner_configs["to"])
        repositories = owner_configs["repositories"] || {}
        repositories.each do |repository, repository_configs|
          table << format_row(fqdn, owner, repository, repository_configs["to"])
        end
      end
      table << <<-FOOTER.chomp
          </tbody>
        </table>
      FOOTER
    end
  end

  def format_row(fqdn, owner, repository, to)
    to = to.first if to.is_a?(Array)
    return "" if to.nil?

    if repository == :all
      repository_column = "(all)"
    else
      repository_column =
        "<a href=\"#{h(repository_url(fqdn, owner, repository))}\">#{h(repository)}</a>"
    end
    <<-ROW
            <tr>
              <td><a href="#{h(owner_url(fqdn, owner))}">#{h(owner)}</a></td>
              <td>#{repository_column}</td>
              <td>#{h(to)}</td>
            </tr>
    ROW
  end

  def owner_url(fqdn, owner)
    "https://#{fqdn}/#{owner}/"
  end

  def repository_url(fqdn, owner, repository)
    "#{owner_url(fqdn, owner)}#{repository}/"
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
