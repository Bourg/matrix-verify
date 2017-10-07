require 'rdl'
require 'types/core'

type Enumerable, :inject, "(%integer) { (%integer, t) -> %integer } -> %integer"

class Matrix
    private_class_method :new

    var_type :@rows, 'Array<Array<%integer>>'
    var_type :@column_count, '%integer'
    
    type '() -> Array<Array<%integer>>'
    def rows
        @rows
    end

    type '() -> %integer x {{x == @rows.size}}'
    def row_count
        @rows.size
    end

    type '() -> %integer x {{x == 0 && @rows.size == 0 || x == @rows[0].size}}'
    def column_count
        @column_count
    end

    type '(Array<Array<%integer>>, %integer) -> self'
    def initialize(rows, column_count)
        @rows = rows
        @column_count = column_count
    end

    type '() -> %bool'
    def valid_matrix?
        var_type :each_row_valid, '%bool'
        each_row_valid = true
        
        @rows.each{|row|
            each_row_valid = each_row_valid && (row.size == column_count)
        }

        column_count >= 0 && each_row_valid

    end

    type '(%integer, %integer) -> %bool'
    def of_size?(num_rows, num_cols)
           row_count == num_rows && column_count == num_cols
    end

    type '(%integer, %integer) -> %bool'
    def valid_matrix_of_size?(num_rows, num_cols)
        valid_matrix? && of_size?(num_rows, num_cols)

    end

    type '() -> Matrix'
    def self.empty
        a = []
        a.instantiate! 'Array<%integer>'

        Matrix.new a, 0
    end

    type '(Array<%integer>) -> Matrix'
    def self.diagonal(values)

	var_type :size, 'Fixnum'
        size = values.size

        return empty if size == 0
        rows = Array.new(size) {|j|
            row = Array.new(size, 0)
            row[j] = values[j]
            row
        }
        rows.instantiate! 'Array<%integer>'
        Matrix.new rows, rows.size
    end

    type '(%integer n {{ n > 0 }}, %integer) -> Matrix m {{ m.valid_matrix_of_size?(n, n) }}'
    def self.scalar(n, value)
        a = Array.new(n, value)
        a.instantiate! '%integer'
        diagonal(a)
    end

    type '(%integer, %integer) -> %integer'
    def ref(i, j)
        @rows[i][j]
    end

    type '(Matrix l {{ l.valid_matrix? }}, Matrix r {{ r.valid_matrix? }}) -> Matrix res {{ res.valid_matrix_of_size?(l.row_count, r.column_count) }}', verify: :later
    def self.*(l, r)
        rows = Array.new(l.row_count) {|i|
            Array.new(r.column_count) {|j|
                range = Array.new(l.column_count){|x| x}
                range.instantiate! '%integer'

                var_type :start, '%integer'
                start = 0
                range.inject(start){|vij, k|
                    vij + l.ref(i, k) * r.ref(k, j)
                }
            }
        }

        rows.instantiate! "Array<%integer>"
        return Matrix.new(rows, r.column_count)
    end
end

rdl_do_verify :later, 11
