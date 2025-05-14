# -*- ruby -*-

require "rake"
require "yaml"
require "erb"

def retrieve_env_var(name, default=nil)
  value = ENV[name] || default
  raise "Environment variable <#{name}> must be set" if value.nil?
  value
end

user = retrieve_env_var("ANSIBLE_GPG_USER", ENV["USER"])
file "ansible/password" => "ansible/password.#{user}.asc" do |task|
  sh("gpg",
     "--output", task.name,
     "--decrypt", task.prerequisites.first)
  chmod(0600, task.name)
end

namespace :password do
  desc "Generate encrypted ansible/password"
  task :encrypt => "ansible/password" do
    user = retrieve_env_var("ANSIBLE_ENCRYPT_GPG_USER")
    key = retrieve_env_var("ANSIBLE_ENCRYPT_GPG_KEY")
    sh("gpg",
       "--armor",
       "--encrypt",
       "--output", "ansible/password.#{user}.asc",
       "--recipient", key,
       "ansible/password")
  end
end

encrypted_files = [
  "ansible/vars/private.yml",
]
encrypted_files.each do |encrypted_file|
  desc "Edit #{encrypted_file}"
  task File.basename(encrypted_file) => "ansible/password" do |task|
    sh("ansible-vault",
       "edit",
       "--vault-password-file", "ansible/password",
       encrypted_file)
  end
end

desc "Apply the Ansible configurations"
task :deploy => "ansible/password" do
  sh("ansible-playbook",
     "--inventory", "hosts",
     "--user", ENV["ANSIBLE_USER"] || ENV["USER"],
     "--vault-password-file", "ansible/password",
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
              <th>Subscribe</th>
              <th>Unsubscribe</th>
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
              <td><a href="#{h(subscribe_url(to))}">Subscribe</a></td>
              <td><a href="#{h(unsubscribe_url(to))}">Unsubscribe</a></td>
            </tr>
    ROW
  end

  def owner_url(fqdn, owner)
    "https://#{fqdn}/#{owner}/"
  end

  def repository_url(fqdn, owner, repository)
    "#{owner_url(fqdn, owner)}#{repository}/"
  end

  def subscribe_url(to)
    "mailto:#{to}?cc=null@commit-email.info&subject=Subscribe&body=subscribe"
  end

  def unsubscribe_url(to)
    "mailto:#{to}?subject=Unsubscribe"
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
