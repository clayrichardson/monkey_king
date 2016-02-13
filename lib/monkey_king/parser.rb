require 'yaml'

module MonkeyKing
  class SecretTag
    yaml_tag '!MK:secret'

    attr_reader :secret

    def initialize( *secret )
      self.secret = *secret
    end

    def init_with( coder )
      case coder.type
      when :scalar
        self.secret = coder.scalar
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

  class EnvTag
    attr_reader :env_tag

    def register(tag)
      if tag.split(':')[1] == 'env'
        self.class.send(:yaml_tag, tag)
      end
    end

    def init_with( coder )
      unless coder.type == :scalar
        raise "Dunno how to handle #{coder.type} for #{coder.inspect}"
      end
    end

    def encode_with(coder)
      coder.style = Psych::Nodes::Mapping::FLOW
      tag=coder.tag.split(':')[2]
      if ENV[tag].nil?
        raise "#{tag} not found in env"
      end
      coder.scalar = ENV[tag]
    end
  end

  class Parser
    def transform(yaml_file)
      tags = get_tags(yaml_file)
      env_tag_instances={}
      tags.each do |tag|
        command = tag.split(':')[1]
        unless command.nil? or command != 'env'
          class_name = tag.split(':')[2]
          unless class_name.nil?
            tag_class = Class.new(EnvTag)

            # Hacky way to give each class a global uniq name
            random_string = [*('a'..'z')].shuffle[0,32].join
            Object.const_set("EnvTag#{class_name}#{random_string}", tag_class)

            tag_instance = tag_class.new
            tag_instance.register(tag)
            env_tag_instances[tag] = tag_instance
          end
        end
      end
      yaml = YAML.load_file(yaml_file)
      yaml.to_yaml
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
      tags.uniq
    end
  end

end
