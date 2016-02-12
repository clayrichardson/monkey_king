require 'yaml'
require 'pry'

module MonkeyKing

  class Secret
    yaml_tag '!MK:secret'

    attr_reader :secret

    def initialize( *secret )
      self.secret = *secret
    end

    def init_with( coder )
      case coder.type
      when :scalar
        self.secret = coder.scalar
      when :seq
        binding.pry
        self.secret = coder.seq
      else
        raise "Dunno how to handle #{coder.type} for #{coder.inspect}"
      end
    end

    def encode_with( coder )
      coder.style = Psych::Nodes::Mapping::FLOW
      coder.scalar = gen_secret(@secret.length)
    end

    protected def secret=( str )
      @secret= str
    end

    def gen_secret(length)
      [*('a'..'z'),*('0'..'9'),*('A'..'Z')].shuffle[0,length].join
    end
  end

  class Parser
    def transform(yaml_file)
      yaml = YAML.load_file(yaml_file).to_yaml
      tags = get_tags(yaml_file)
      yaml
    end

    def get_tags(yaml_file)
      tags = []
      nodes = Psych.parse_file(yaml_file)
      # traverse the tree and return
      nodes.each do |n|
        if n.class == Psych::Nodes::Scalar
          unless n.tag.nil?
            tags << n.tag
          end
        end
      end
      tags
    end
  end

end
