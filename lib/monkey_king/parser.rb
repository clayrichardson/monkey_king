require 'yaml'
require 'securerandom'
require 'sexpistol'
require 'pry'

module MonkeyKing
  @@variables = {}

  def self.variables
    @@variables
  end

  def self.variables=(value)
    @@variables = value
  end

  def self.set_variable(name, value)
    @@variables[name] = value
    return value
  end

  class FunctionTag
    attr_accessor :scalar

    def register(tag)
      self.class.send(:yaml_tag, tag)
    end

    def init_with(coder)
      unless coder.type == :scalar
        raise "Dunno how to handle #{coder.type} for #{coder.inspect}"
      end
      self.scalar = coder.scalar
    end

    def encode_with(coder)
      coder.style = Psych::Nodes::Mapping::FLOW
      s_expression = coder.tag.sub(/^!MK:/, '')
      s_expression.gsub!(/,/, ' ')
      expression_tree = Sexpistol.new.parse_string(s_expression)
      coder.scalar = expand(expression_tree).first
    end


    def argment_count_checking(params_count, legit_count, function_name)
      if params_count > legit_count
        raise "too many arguments for #{function_name} function (#{params_count} of #{legit_count})"
      elsif params_count < legit_count
        raise "not enough arguments for #{function_name} function (#{params_count} of #{legit_count})"
      end
    end

    def expand(expression)
      if expression.is_a? Array
        function_array = []
        expression.each do |ex|
          function_array << expand(ex)
        end

        process_array = []

        while !function_array.empty? do
          key_word = function_array.shift
          case key_word
          when :write
            params = function_array.shift
            argment_count_checking(params.size, 2, key_word)
            key = params.first
            value = params.last
            raise "attempting to redefine immutable variable #{key}, exiting" unless MonkeyKing.variables[key].nil?
            process_array << MonkeyKing.set_variable(key, value.to_s)
          when :read
            params = function_array.shift
            argment_count_checking(params.size, 1, key_word)
            key = params.first
            raise "unresolved variables #{key}" if MonkeyKing.variables[key].nil?
            process_array << MonkeyKing.variables[key]
          when :secret
            params = function_array.shift
            argment_count_checking(params.size, 1, key_word)
            raise "argument error for secret function: got #{params.first.class} instead of Fixnum" if !params.first.is_a? Fixnum
            length = params.first
            process_array << gen_secret(length)
          when :env
            params = function_array.shift
            argment_count_checking(params.size, 1, key_word)
            key = params.first.to_s
            process_array << get_env(key)
          when :write_value
            params = function_array.shift
            argment_count_checking(params.size, 1, key_word)
            key = params.first
            process_array << MonkeyKing.set_variable(key, self.scalar)
          when :format
            params = function_array.shift
            formating_string = params.pop
            raise('format template not found') if formating_string.nil?
            replace_count =  formating_string.scan(/%s/).count
            argment_count_checking(params.size, replace_count, key_word)
            params.each do |param|
              formating_string = formating_string.sub(/%s/, param.to_s)
            end
            process_array << formating_string
          else
            process_array << key_word
          end
        end
        return process_array

      elsif expression.is_a? Symbol
        return expression
      elsif expression.is_a? Numeric
        return expression
      elsif expression.is_a? String
        return expression
      else
        raise "unknown expression #{expression}"
      end
    end

    def get_env(key)
      raise "#{key} not found in env" if ENV[key].nil?
      return ENV[key]
    end

    def gen_secret(length)
      return [*('a'..'z'),*('0'..'9'),*('A'..'Z')].shuffle[0,length].join
    end
  end

  class Parser

    def transform(yaml_file)
      function_tag_instances = {}
      tags = get_tags(yaml_file)

      tags.each do |tag|
        if tag =~ /!MK:/
          tag_class = Class.new(FunctionTag)
          random_string = SecureRandom.uuid.gsub(/-/, '')
          Object.const_set("FunctionTag#{random_string}", tag_class)
          tag_instance = tag_class.new
          tag_instance.register(tag)
          function_tag_instances[tag] = tag_instance
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
