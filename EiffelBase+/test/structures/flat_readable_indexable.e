deferred class 
	FLAT_READABLE_INDEXABLE [G]
	
feature -- Access

	item alias "[]" (i: INTEGER_32): G
			-- Entry at position `i'
		require
			valid_index: valid_index (i)
		deferred
		end

	new_cursor: FLAT_INDEXABLE_ITERATION_CURSOR [G]
			-- Fresh cursor associated with current structure
		do
			create Result.make (Current)
			Result.start
		ensure -- from ITERABLE
			result_attached: Result /= Void
		end
	
feature -- Measurement

	index_set: FLAT_INTEGER_INTERVAL
			-- Range of acceptable indexes
		deferred
		ensure
			not_void: Result /= Void
		end
	
	
feature -- Status report

	valid_index (i: INTEGER_32): BOOLEAN
			-- Is `i' a valid index?
		deferred
		ensure
			only_if_in_index_set: Result implies ((i >= index_set.lower) and (i <= index_set.upper))
		end

end -- class FLAT_READABLE_INDEXABLE

