deferred class
	FLAT_SUBSET_STRATEGY [G]

feature -- Comparison

	disjoint (set1, set2: FLAT_LINEAR_SUBSET [G]): BOOLEAN
			-- Are `set1' and `set2' disjoint?
		require
			sets_exist: set1 /= Void and set2 /= Void
			same_rule: set1.object_comparison = set2.object_comparison
		deferred
		end

feature -- Basic operations

	symdif (set1, set2: FLAT_LINEAR_SUBSET [G])
			-- Remove all items of `set1' that are also in `set2', and add all
			-- items of `set2' not already present in `set1'.
		require
			sets_exist: set1 /= Void and set2 /= Void
			same_rule: set1.object_comparison = set2.object_comparison
		deferred
		end

end -- class FLAT_SUBSET_STRATEGY
