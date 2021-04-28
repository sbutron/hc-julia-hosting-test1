@inline @views function get_column(matrix::Array, column_index::Integer)
return matrix[:, column_index]
end

@inline @views function get_row(matrix::Array, row_index::Integer)
return matrix[row_index, :]
end

@inline @views function sorting_index(matrix::Array, column_index::Integer)
    sorted_index = sortperm(get_column(matrix,column_index))
    return sorted_index
end

@inline @views function get_row_column(matrix::Array, row_index::Integer, column_index::Integer)
    return matrix[row_index, column_index]
end
