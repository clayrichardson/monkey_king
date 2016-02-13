require 'mothership'
require 'highline/import'
require 'pry'

module MonkeyKing
  class CloneCommand < Mothership
    option :help, :desc => "Show command usage", :alias => "-h",
      :default => false

    desc "Show Help"
    input :command, :argument => :optional
    def help
      if name = input[:command]
        if cmd = @@commands[name.gsub("-", "_").to_sym]
          Mothership::Help.command_help(cmd)
        else
          unknown_command(name)
        end
      else
        Mothership::Help.basic_help(@@commands, @@global)
      end
    end

    desc "Clone the repo and replace secret and env annotation"
    input(:repo) { ask("Input the github repo of a existing deployment") }
    def clone
      repo = input[:repo]
      directory = repo.split('/').last.split('.').first
      parser = MonkeyKing::Parser.new

      raise 'Failed to clone' unless system("git clone #{repo} #{directory}")
      deployment_yaml_files = []

      deployment_yaml_files += Dir.glob("#{directory}/deployments/*.yml")
      deployment_yaml_files += Dir.glob("#{directory}/bosh-init/*.yml")

      deployment_yaml_files.each do |file|
        puts "Transforming #{file}..."
        transformed_content = parser.transform(file)
        File.open(file, "w") do |overwrite_file|
          overwrite_file.write transformed_content
        end
      end
    end
  end
end
