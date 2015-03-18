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
    @associations = options[:associations] || []
  end

  # will overwrite repeated constraint keys
  def where(where_constraints)
    @where_constraints.merge(where_constraints)
  end

  def includes(associations)
    @associations += associations
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

    @associations.each do |assoc|
      objects.each do |obj|
        @klass.assoc_hash[obj] ||= {}
        @klass.assoc_hash[obj][assoc] = obj.send(assoc)
      end
    end

    objects
  end

  def method_missing(method, *args)
    evaluate.send(method, *args)
  end
end

class SQLObject
  extend Searchable
end
