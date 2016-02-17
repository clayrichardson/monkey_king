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
			raise 'Failed to clone' unless system("git clone #{input[:repo]}")
      binding.pry
			puts a
		end

	end
end
