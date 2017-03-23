note
	description: "The gui view of the alias analysis tool."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-19 18:10:50 +0300 (Thu, 19 Nov 2015) $"
	revision: "$Revision: 98119 $"

class
	CHANGE_ANALYZER_GUI

inherit
	ALIAS_ANALYZER_GUI
		redefine
			make,
			reset,
			on_stone_changed
		end

create
	make

feature {NONE}

	change_analysis_button: EV_BUTTON
			-- To activate the change analyser

	make (a_develop_window: EB_DEVELOPMENT_WINDOW)
		do
			Precursor (a_develop_window)

			create change_analysis_button.make_with_text_and_action ("Change", agent on_change_analysis)
			change_analysis_button.set_tooltip ("Change Calculus")
			change_analysis_button.disable_sensitive


			go_i_th (count - 1)
			if attached {EV_VERTICAL_BOX} item as v then
				v.extend (change_analysis_button)
				v.disable_item_expand (v.last)
			end
		end

	reset
		do
			Precursor
			change_analysis_button.disable_sensitive
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
				feature_view.set_stone (a_stone)
				step_over_button.enable_sensitive
				step_out_button.enable_sensitive
				show_graph_button.enable_sensitive

				change_analysis_button.enable_sensitive

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
				create {CHANGE_ANALYSIS_RUNER} alias_analysis_runner.make (
						p,
						l_last,
						agent do feature_view.editor.refresh end
					)
			end
		end

	on_change_analysis
		do
			alias_info_text.set_text ("it Works!")
			if alias_analysis_runner.is_done then
				change_analysis_button.disable_sensitive
			end
		end

invariant
	change_analysis_button /= Void

note
	copyright: "Copyright (c) 1984-2015, Eiffel Software"
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
