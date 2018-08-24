note
	description: "[
		Containers that use a lock to protect their items.
		]"
	author: "Nadia Polikarpova"
	status: ghost
	model: lock, locked
	manual_inv: true
	false_guards: true

deferred class
	V_LOCKER [G]

feature -- Specification

	locked: MML_SET [G]
			-- Locked items.

	lock: V_LOCK [G]
			-- Lock.

invariant
	lock_exists: lock /= Void
	locked_non_void: locked.non_void
	lock_non_current: lock /= Current
	items_locked: locked <= lock.locked

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
