require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      self_foreign_key = self.send(through_options.foreign_key)

      raw = DBConnection.execute(<<-SQL).first
        SELECT
          #{source_options.table_name}.*
        FROM
          #{source_options.table_name}
        JOIN
          #{through_options.table_name}
          ON #{through_options.table_name}.#{source_options.foreign_key}
          = #{source_options.table_name}.#{source_options.primary_key}
        WHERE
          #{through_options.table_name}.#{through_options.primary_key}
          = #{self_foreign_key}
      SQL

      source_options.model_class.new(raw)
    end
  end

  def has_many_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      if through_options.is_a?(HasManyOptions) && source_options.is_a?(HasManyOptions)
        join_on_string = "#{through_options.table_name}."\
                         "#{through_options.primary_key} = "\
                         "#{source_options.table_name}."\
                         "#{source_options.foreign_key}"
        where_string = "#{through_options.table_name}."\
                       "#{through_options.foreign_key} = "\
                       "#{self.id}"
      elsif through_options.is_a?(HasManyOptions)
        join_on_string = "#{through_options.table_name}."\
                         "#{source_options.foreign_key} = "\
                         "#{source_options.table_name}."\
                         "#{source_options.primary_key}"
        where_string = "#{through_options.table_name}."\
                       "#{through_options.foreign_key} = "\
                       "#{self.id}"
      else
        join_on_string = "#{through_options.table_name}."\
                         "#{source_options.primary_key} = "\
                         "#{source_options.table_name}."\
                         "#{source_options.foreign_key}"
        where_string = "#{through_options.table_name}."\
                       "#{through_options.primary_key} = "\
                       "#{self.send(through_options.foreign_key)}"
      end

      raw = DBConnection.execute(<<-SQL)
        SELECT
          #{source_options.table_name}.*
        FROM
          #{source_options.table_name}
        JOIN
          #{through_options.table_name}
          ON #{join_on_string}
        WHERE
          #{where_string}
      SQL

      source_options.model_class.parse_all(raw)
    end
  end
end
