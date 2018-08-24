note
	description: "Iterators to read from maps in linear order."
	author: "Nadia Polikarpova"
	model: target, sequence, index_
	manual_inv: true
	false_guards: true

deferred class
	V_MAP_ITERATOR [K, V]

inherit
	V_ITERATOR [V]
		rename
			sequence as value_sequence
		redefine
			target
		end

feature -- Access

	key: K
			-- Key at current position.
		deferred
		end

	target: V_MAP [K, V]
			-- Table to iterate over.

feature -- Cursor movement

	search_key (k: K)
			-- Move to a position where key is equivalent to `k'.
			-- If `k' does not appear, go after.
			-- (Use object equality.)
		note
			modify_model: index_, Current_
		deferred
		end

feature -- Specification

	sequence: MML_SEQUENCE [K]
			-- Sequence of keys.
		note
			status: ghost
			replaces: value_sequence
		attribute
		end

	value_sequence_from (seq: like sequence; m: like target.map): MML_SEQUENCE [V]
			-- Value sequnce for key sequence `seq' and target map `m'.			
		do
			Result := m.sequence_image (seq)
		ensure
			same_count: Result.count = seq.count
		end

	is_model_equal (other: like Current): BOOLEAN
			-- Is iterator traversing the same container in the same order and is at the same position at `other'?		
		note
			status: ghost, functional, nonvariant
		do
			Result := target = other.target and sequence = other.sequence and index_ = other.index_
		end

invariant
	target_domain_constraint: target.map.domain ~ sequence.range
	value_sequence_definition: value_sequence ~ value_sequence_from (sequence, target.map)

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
