note
	description: "[
		Two-dimensional arrays.
		Indexing of rows and columns starts from 1.
		]"
	author: "Nadia Polikarpova"
	model: sequence, column_count
	manual_inv: true
	false_guards: true

class
	V_ARRAY2 [G]

inherit
	V_MUTABLE_SEQUENCE [G]
		rename
			item as flat_item,
			put as flat_put,
			at as flat_at
		redefine
			upper,
			flat_put
		end

create
	make,
	make_filled

feature {NONE} -- Initialization

	make (n, m: INTEGER)
			-- Create array with `n' rows and `m' columns; set all values to default.
		do
			row_count := n
			column_count := m
			create array.make (1, n * m)
			create sequence.constant (({G}).default, n * m)
		end

	make_filled (n, m: INTEGER; v: G)
			-- Create array with `n' rows and `m' columns; set all values to `v'.
		do
			row_count := n
			column_count := m
			create array.make_filled (1, n * m, v)
			create sequence.constant (v, n * m)
		end

feature -- Initialization

	copy_ (other: like Current)
			-- Initialize by copying all the items of `other'.
		note
			modify_model: sequence, column_count, Current_
		do
			if other /= Current then
				row_count := other.row_count
				column_count := other.column_count
				create array.copy_ (other.array)
				sequence := other.sequence
			end
		end

feature -- Access

	item alias "[]" (i, j: INTEGER): G assign put
			-- Item at row `i' and column `j'.
		do
			Result := flat_item (flat_index (i, j))
		end

	flat_item (i: INTEGER): G assign flat_put
			-- Item at dlat index `i'.
		do
			Result := array [i]
		end

feature -- Measurement

	row_count: INTEGER
			-- Number of rows.

	column_count: INTEGER
			-- Number of columns.

	count: INTEGER
			-- Number of elements.
		do
			Result := row_count * column_count
		end

	flat_index (i, j: INTEGER): INTEGER
			-- Flat index at row `i' and column `j'.
		do
			Result := (i - 1) * column_count + j
		end

	row_index (i: INTEGER): INTEGER
			-- Row that corresponds to flat index `i'.
		do
			Result := (i - 1) // column_count + 1
		end

	column_index (i: INTEGER): INTEGER
			-- Column that corresponds to flat index `i'.
		do
			Result := (i - 1) \\ column_count + 1
		end

	Lower: INTEGER = 1
			-- Lower flat index.

	upper: INTEGER
			-- Upper flat_index.
		do
			Result := row_count * column_count
		end

feature -- Search

	has_row (i: INTEGER): BOOLEAN
			-- Does array contain row `i'?
		do
			Result := 1 <= i and i <= row_count
		end

	has_column (j: INTEGER): BOOLEAN
			-- Does array contain column `j'?
		do
			Result := 1 <= j and j <= column_count
		end

feature -- Iteration

	flat_at (i: INTEGER): V_ARRAY_ITERATOR [G]
			-- New iterator pointing at flat position `i'.
		do
			create Result.make (Current, i)
		end

feature -- Comparison

	is_equal_ (other: like Current): BOOLEAN
			-- Is array made of the same items as `other'?
			-- (Use reference comparison.)
		do
			if other = Current then
				Result := True
			else
				Result := column_count = other.column_count and array.is_equal_ (other.array)
			end
		end

feature -- Replacement

	put (v: G; i, j: INTEGER)
			-- Replace value at row `i' and column `j' with `v'.
		note
			modify_model: sequence, Current_
		do
			flat_put (v, flat_index (i, j))
		end

	flat_put (v: G; i: INTEGER)
			-- Replace value at position `i' with `v'.
		do
			array.put (v, i)
			sequence := sequence.replaced_at (i, v)
		end

feature {V_CONTAINER, V_ITERATOR} -- Implemantation

	array: V_ARRAY [G]
			-- Flat representation.

feature -- Specification

	is_model_equal (other: like Current): BOOLEAN
			-- Is the abstract state of `Current' equal to that of `other'?
		note
			status: ghost, functional
		do
			Result := sequence ~ other.sequence and column_count = other.column_count
		end

invariant
	array_exists: array /= Void
	array_lower_definition: array.lower_ = 1
	sequence_implementation: sequence = array.sequence
	lower_definition: lower_ = 1
	column_count_empty: sequence.is_empty implies column_count = 0
	column_count_nonempty: not sequence.is_empty implies column_count > 0
	row_count_definition: row_count * column_count = sequence.count

note
	copyright: "Copyright (c) 1984-2014, Eiffel Software and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
