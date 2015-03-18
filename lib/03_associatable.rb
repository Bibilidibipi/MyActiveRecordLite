require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def name
    @name
  end

  def foreign_key
    @foreign_key ||= "#{@parent_class_name.to_s.downcase.singularize}_id".to_sym
  end

  def primary_key
    @primary_key ||= "id".to_sym
  end

  def class_name
    @class_name ||= name
    @class_name.to_s.capitalize.singularize
  end

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @parent_class_name = name
    options.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @parent_class_name = self_class_name
    options.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      foreign_key = self.send(options.foreign_key) || 'NULL'
      primary_key = options.primary_key

      model_table = options.table_name

      raw = DBConnection.execute(<<-SQL).first
        SELECT
          *
        FROM
          #{model_table}
        WHERE
          #{foreign_key} = #{model_table}.#{primary_key}
      SQL

      raw.nil? ? nil : options.model_class.new(raw)
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)

    define_method(name) do
      foreign_key = options.foreign_key
      primary_key = self.send(options.primary_key)

      model_table = options.table_name

      raw = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{model_table}
        WHERE
          #{primary_key} = #{model_table}.#{foreign_key}
      SQL

      if raw.nil?
          nil
      else
        [].tap do |many|
          raw.each do |data|
            many << options.model_class.new(data)
          end
        end
      end

    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
