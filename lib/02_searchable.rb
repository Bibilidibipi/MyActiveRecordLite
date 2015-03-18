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

    objects = @klass.parse_all DBConnection.execute(<<-SQL, *@where_constraints.values)
      SELECT
        *
      FROM
        #{@klass.table_name}
      WHERE
        #{where_string}
    SQL

    # get all assoc objects
    unless @associations.keys.all? do |assoc|
      @klass.assoc_options[assoc].include?(assoc)
    end
      raise "Invalid inclusion"
    end
    belongs_to_assocs = @associations.keys.select do |assoc|
      @klass.assoc_options[assoc].is_a?(BelongsToOptions)
    end
    has_many_assocs = @associations.keys.select do |assoc|
      @klass.assoc_options[assoc].is_a?(HasManyOptions)
    end
    #other_assocs = @associations                                          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    belongs_to_assocs.each do |assoc|
      options = @klass.assoc_options[assoc]
      foreign_keys = []
      objects.each do |obj|
        foreign_keys << obj.foreign_key
      end

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
          @associations[assoc] = assoc_obj if assoc_obj.primary_key == obj.foreign_key
        end

        # cache association for object
        obj.assoc_hash[assoc] = @associations[assoc]
      end
    end

    has_many_assocs.each do |assoc|
      options = @klass.assoc_options[assoc]
      primary_keys = []
      objects.each do |obj|
        primary_keys << obj.primary_key
      end

      assoc_objects = @klass.parse_all DBConnection.execute(<<-SQL)
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
          @associations[assoc] << assoc_obj if assoc_obj.foreign_key == obj.primary_key
        end

        # cache association for object
        obj.assoc_hash[assoc] = @associations[assoc]
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
