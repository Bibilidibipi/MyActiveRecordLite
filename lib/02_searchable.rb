require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    Relation.new(self, params)
  end
end

class SQLObject
  extend Searchable
end

class Relation
  def initialize(klass, constraint)
    @klass = klass
    @constraints = constraint
  end

  # will overwrite repeated constraint keys
  def where(constraint)
    @constraints.merge(constraint)
  end

  def evaluate
    where_string = @constraints.keys.map{ |k| "#{k} = ?" }.join(" AND ")

    @klass.parse_all DBConnection.execute(<<-SQL, *@constraints.values)
      SELECT
        *
      FROM
        #{@klass.table_name}
      WHERE
        #{where_string}
    SQL
  end

  def method_missing(method, *args)
    evaluate.send(method, *args)
  end
end

class SQLObject
  extend Searchable
end
