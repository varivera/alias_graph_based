note
	description:
		"Action sequences for EV_STANDARD_DIALOG."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	keywords: "event, action, sequence"
	date: "Generated!"
	revision: "Generated!"

deferred class
	 EV_STANDARD_DIALOG_ACTION_SEQUENCES

inherit
	EV_ACTION_SEQUENCES

feature {NONE} -- Implementation

	implementation: EV_STANDARD_DIALOG_ACTION_SEQUENCES_I
		deferred
		end

feature -- Event handling


	ok_actions: EV_NOTIFY_ACTION_SEQUENCE
			-- Actions to be performed when user clicks OK.
			-- Note: This is renamed in some descendents
			-- i.e. in EV_PRINT_DIALOG it is renamed to print_actions
			-- and is performed when the user clicks "print".
		do
			Result := implementation.ok_actions
		ensure
			not_void: Result /= Void
		end


	cancel_actions: EV_NOTIFY_ACTION_SEQUENCE
			-- Actions to be performed when user cancels.
		do
			Result := implementation.cancel_actions
		ensure
			not_void: Result /= Void
		end

note
	copyright:	"Copyright (c) 1984-2014, Eiffel Software and others"
	license:	"Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"




end

