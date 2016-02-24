require 'mothership'
require 'highline/import'

module MonkeyKing
  class CloneCommand < Mothership

    desc "Clone the repo and replace secret and env annotation"
    input :repo, :argument => true
    input :dir, :argument => :splat
    def clone
      repo = input[:repo]
      sub_dir = input[:dir]

      directory = repo.split('/').last.split('.').first
      parser = MonkeyKing::Parser.new

      raise 'Failed to clone' unless system("git clone #{repo} #{directory}")
      deployment_yaml_files = []

      sub_dir.each do |d|
        deployment_yaml_files += Dir.glob("#{directory}/#{d}/*.yml")
      end

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
