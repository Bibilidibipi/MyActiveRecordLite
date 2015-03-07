require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    DBConnection.execute2(<<-SQL).first.map { |string| string.to_sym }
      SELECT
        *
      FROM
        #{table_name}
    SQL
  end

  def self.finalize!

    columns.each do |name|
      define_method("#{name}") do
        attributes[name]
      end

      define_method("#{name}=") do |val|
        attributes[name] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".tableize
  end

  def self.all
    parse_all DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
  end

  def self.parse_all(results)
    [].tap do |data_as_objects|
      results.each do |params|
        data_as_objects << self.new(params)
      end
    end
  end

  def self.find(id)
    parse_all(DBConnection.execute(<<-SQL)).first
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end

      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    [].tap do |values|
      self.class.columns.each do |col_name|
        values << send(col_name)
      end
    end
  end

  def insert
    columns = self.class.columns[1..-1]
    col_names = columns.join(", ")
    question_marks = (["?"]*(columns.length)).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values[1..-1])
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns[1..-1]
    set_vals_string = columns.join(" = ?, ") + " = ?"

    DBConnection.execute(<<-SQL, *attribute_values[1..-1], id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_vals_string}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
