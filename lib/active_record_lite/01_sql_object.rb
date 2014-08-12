require_relative 'db_connection'
require 'active_support/inflector'
require 'debugger'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  
  def self.columns
    cols = DBConnection.execute2("SELECT #{table_name}.* FROM #{table_name}")[0].map { |col| col.to_sym }
    
    cols.each do |col|
      define_method(col) do
        attributes[col]
      end

      define_method("#{col}=") do |arg|
        attributes[col] = arg
      end
    end
    
    cols
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{table_name}"))

  end
  
  def self.parse_all(results)
    results.map { |object_info| self.new(object_info) }
  end

  def self.find(id)
    object_info = DBConnection.execute(<<-SQL, id)
    SELECT
    *
    FROM
    #{table_name}
    WHERE
    id = ?
    SQL
    parse_all(object_info).first
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = "(?, ?, ?)"
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      #{question_marks}
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = attributes)
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym
      unless self.class.columns.include?(attr_sym)
        raise "unknown attribute '#{attr_name}'"
      else
        attributes[attr_sym] = value
      end
    end
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end

  def update
    col_names = self.class.columns.map { |col| "#{col} = ?"}.join(", ")
    p "attribute values #{attribute_values}"
    p "col_names #{col_names}"
    #debugger
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    UPDATE
    #{self.class.table_name}
    SET
    #{col_names}
    WHERE
    id = ?
    SQL
  end

  def attribute_values
    self.class.columns.map { |col| self.send(col) }
  end

end
