require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map { |key, value| "#{key} = ?" }.join(" AND ")
    search = params.values
    p where_line
    p search
    object_info = DBConnection.execute(<<-SQL, search)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL
    parse_all(object_info)
  end
end

class SQLObject
  extend Searchable
end
