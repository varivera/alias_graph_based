note
	description: "The gui view of the MQ analysis tool."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-19 18:10:50 +0300 (Thu, 19 Nov 2015) $"
	revision: "$Revision: 98119 $"

class
	MQ_ANALYZER

inherit
	EV_HORIZONTAL_BOX

create
	make

feature {NONE}

	feature_view: EB_ROUTINE_FLAT_FORMATTER
	mq_info_text: EV_TEXT

	mq_analysis_runner: MQ_ANALYSIS_RUNNER


	make (a_develop_window: EB_DEVELOPMENT_WINDOW)
		local
			l_drop_actions: EV_PND_ACTION_SEQUENCE
		do
			default_create

			create l_drop_actions
			l_drop_actions.extend (agent on_stone_changed)

			create feature_view.make (a_develop_window)
			feature_view.set_editor_displayer (feature_view.displayer_generator.any_generator.item ([a_develop_window, l_drop_actions]))
			feature_view.set_combo_box (create {EV_COMBO_BOX}.make_with_text ((create {INTERFACE_NAMES}).l_Flat_view))
			feature_view.on_shown
			feature_view.editor.margin.margin_area.pointer_button_release_actions.wipe_out

			create mq_info_text
			mq_info_text.disable_edit

			extend (feature_view.editor.widget)

			extend (mq_info_text)
		end

	reset
		do
			feature_view.editor.clear_window
			mq_info_text.set_text ("")
			mq_analysis_runner := Void
		end

	on_stone_changed (a_stone: STONE)
		local
			l_el: EIFFEL_EDITOR_LINE
			l_line_number: INTEGER_32
			l_last: EDITOR_TOKEN_ALIAS_BREAKPOINT

			l_internal: INTERNAL
			l_field_index: INTEGER_32
			l_done: BOOLEAN
		do
			reset
			if
				attached {FEATURE_STONE} a_stone as fs and then
				attached {E_ROUTINE} fs.e_feature as r and then
				attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as p
			then
				--feature_view.set_stone (a_stone)
				{ISE_RUNTIME}.check_assert (False).do_nothing
				feature_view.set_stone (fs)
				{ISE_RUNTIME}.check_assert (True).do_nothing

				from
					l_el := feature_view.editor.text_displayed.first_line
					l_line_number := 1
				until
					l_el = Void
				loop
					if
						attached {EDITOR_TOKEN_BREAKPOINT} l_el.real_first_token as etb and then
						etb.pebble /= Void
					then
						if l_internal = Void then
							create l_internal
							from
								l_field_index := 1
							until
								l_done
							loop
								if l_internal.field (l_field_index, l_el) = etb then
									l_done := True
								else
									l_field_index := l_field_index + 1
								end
							end
						end
						create l_last.make_replace (etb, l_line_number, l_last)
						l_internal.set_reference_field (l_field_index, l_el, l_last)
					end
					l_el := l_el.next
					l_line_number := l_line_number + 1
				end
				create mq_analysis_runner.make (
						p,
						l_last,
						agent do feature_view.editor.refresh end
					)

				mq_analysis_runner.step_end

			end
		end


invariant
	feature_view /= Void


note
	copyright: "Copyright (c) 1984-2017, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
