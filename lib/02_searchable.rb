require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    Relation.new(self, where_constraints: params)
  end
end

class SQLObject
  extend Searchable
end

class Relation
  def initialize(klass, options)
    @klass = klass
    @where_constraints = options[:where_constraints] || {}
    @associations = options[:associations] || {}
  end

  # will overwrite repeated constraint keys
  def where(where_constraints)
    @where_constraints.merge(where_constraints)
  end

  def includes(associations)
    @associations.merge(associations)
  end

  def evaluate
    where_string = @where_constraints.keys.map{ |k| "#{k} = ?" }.join(" AND ")
    where = where_string.empty? ? "" : "WHERE #{where_string}"

    objects = @klass.parse_all DBConnection.execute(<<-SQL, *@where_constraints.values)
      SELECT
        *
      FROM
        #{@klass.table_name}
      #{where}
    SQL

    unless @associations.keys.all? do |assoc|
      @klass.assoc_options.keys.include?(assoc)
    end
      raise "Invalid inclusion"
    end
    belongs_to_assocs = @associations.keys.select do |assoc|
      @klass.assoc_options[assoc].is_a?(BelongsToOptions)
    end
    has_many_assocs = @associations.keys.select do |assoc|
      @klass.assoc_options[assoc].is_a?(HasManyOptions)
    end

    belongs_to_assocs.each do |assoc|
      options = @klass.assoc_options[assoc]
      foreign_keys = []
      objects.each do |obj|
        foreign_keys << obj.send("#{options.foreign_key}")
      end
      foreign_keys = foreign_keys.to_s.gsub('[', '(').gsub(']', ')')

      assoc_objects = @klass.parse_all DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{@options.table_name}.#{options.primary_key} IN #{foreign_keys}
      SQL

      # correlate objects
      objects.each do |obj|
        assoc_objects.each do |assoc_obj|
          @associations[assoc] = assoc_obj if assoc_obj.id == obj.send("#{options.foreign_key}")
        end

        # cache association for object
        obj.assoc_hash[assoc] = @associations[assoc].dup
      end
    end

    has_many_assocs.each do |assoc|
      options = @klass.assoc_options[assoc]
      primary_keys = []
      objects.each do |obj|
        primary_keys << obj.id
      end
      primary_keys = primary_keys.to_s.gsub('[', '(').gsub(']', ')')

      assoc_objects = options.model_class.parse_all DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          #{options.table_name}.#{options.foreign_key} IN #{primary_keys}
      SQL

      #correlate objects
      objects.each do |obj|
        @associations[assoc] ||= []
        assoc_objects.each do |assoc_obj|
          @associations[assoc] << assoc_obj if assoc_obj.send("#{options.foreign_key}") == obj.id
        end

        # cache association for object
        obj.assoc_hash[assoc] = @associations[assoc].dup
      end
    end

    objects
  end

  def method_missing(method, *args)
    if @associations.keys.include?(method)
      return @associations[method]
    end
    evaluate.send(method, *args)
  end
end

class SQLObject
  extend Searchable
end
