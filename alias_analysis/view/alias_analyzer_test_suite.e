note
	description: "The test suite view of the alias analysis tool."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-19 18:10:50 +0300 (Thu, 19 Nov 2015) $"
	revision: "$Revision: 98119 $"

class
	ALIAS_ANALYZER_TEST_SUITE

inherit
	EV_VERTICAL_BOX
	SHARED_EIFFEL_PROJECT
		undefine
			default_create,
			is_equal,
			copy
		end

create
	make

feature {NONE}

	stats_total, stats_failures, stats_ok: SD_TOOL_BAR_BUTTON
	overview: EV_TREE
	expected: EV_TEXT
	actual: EV_TEXT

	standard_text_color, warning_text_color: EV_COLOR
	ok_icon, fail_icon: EV_PIXMAP
	test_info: TUPLE [passed: BOOLEAN; expected, actual: STRING_8]

	make
		local
			l_tool_bar: SD_TOOL_BAR
			l_stats: SD_TOOL_BAR
			l_overview_box, l_expected_box, l_actual_box: EV_VERTICAL_BOX
			l_comparison_box: EV_HORIZONTAL_BOX
			l_split_area: EV_HORIZONTAL_SPLIT_AREA
		do
			ok_icon := (create {EB_SHARED_PIXMAPS}).icon_pixmaps.tool_output_successful_icon
			fail_icon := (create {EB_SHARED_PIXMAPS}).icon_pixmaps.tool_output_failed_icon

			create l_tool_bar.make
			l_tool_bar.extend (create_tool_bar_button ("Run Test Suite", (create {EB_SHARED_PIXMAPS}).icon_pixmaps.debug_run_icon, agent run_tests))
			l_tool_bar.extend (create_tool_bar_button ("Clear", Void, agent reset))
			l_tool_bar.compute_minimum_size

			stats_total := create_tool_bar_button ("-", Void, Void)
			stats_failures := create_tool_bar_button ("-", Void, Void)
			stats_ok := create_tool_bar_button ("-", Void, Void)
			create l_stats.make
			l_stats.extend (create_tool_bar_button ("Total:", Void, Void))
			l_stats.extend (stats_total)
			l_stats.extend (create {SD_TOOL_BAR_SEPARATOR}.make)
			l_stats.extend (create_tool_bar_button ("Failures:", fail_icon, Void))
			l_stats.extend (stats_failures)
			l_stats.extend (create {SD_TOOL_BAR_SEPARATOR}.make)
			l_stats.extend (create_tool_bar_button ("Ok:", ok_icon, Void))
			l_stats.extend (stats_ok)
			l_stats.compute_minimum_size

			create overview
			overview.select_actions.extend (agent
				do
					if
						attached overview.selected_item as l_tn and then
						attached {like test_info} l_tn.data as l_test_info
					then
						expected.set_foreground_color (standard_text_color)
						expected.set_text (l_test_info.expected)
						actual.set_text (l_test_info.actual)
					else
						expected.set_text ("")
						actual.set_text ("")
					end
				end)
			create l_overview_box
			l_overview_box.extend (create {EV_LABEL}.make_with_text ("Tests:"))
			l_overview_box.disable_item_expand (l_overview_box.last)
			l_overview_box.extend (l_stats)
			l_overview_box.disable_item_expand (l_overview_box.last)
			l_overview_box.extend (overview)

			create expected
			expected.disable_edit
			expected.disable_word_wrapping
			create l_expected_box
			l_expected_box.extend (create {EV_LABEL}.make_with_text ("Expected:"))
			l_expected_box.disable_item_expand (l_expected_box.last)
			l_expected_box.extend (expected)

			create actual
			actual.disable_edit
			actual.disable_word_wrapping
			create l_actual_box
			l_actual_box.extend (create {EV_LABEL}.make_with_text ("Actual:"))
			l_actual_box.disable_item_expand (l_actual_box.last)
			l_actual_box.extend (actual)

			create l_comparison_box
			l_comparison_box.extend (l_expected_box)
			l_comparison_box.extend (l_actual_box)

			create l_split_area
			l_split_area.extend (l_overview_box)
			l_split_area.extend (l_comparison_box)

			default_create
			extend (l_tool_bar)
			disable_item_expand (l_tool_bar)
			extend (l_split_area)

			standard_text_color := expected.foreground_color
			create warning_text_color.make_with_8_bit_rgb (255, 0, 0)
		end

	create_tool_bar_button (a_text: STRING_8; a_pixmap: EV_PIXMAP; a_select_action: PROCEDURE [ANY, TUPLE]): SD_TOOL_BAR_BUTTON
		require
			a_text /= Void
		do
			create Result.make
			Result.set_text (a_text)
			if a_pixmap /= Void then
				Result.set_pixmap (a_pixmap)
			end
			if a_select_action /= Void then
				Result.select_actions.extend (a_select_action)
			end
		end

	reset
		do
			stats_total.set_text ("-")
			stats_failures.set_text ("-")
			stats_ok.set_text ("-")
			overview.wipe_out
			expected.set_foreground_color (standard_text_color)
			expected.set_text ("")
			actual.set_text ("")
		end

	run_tests
		local
			l_testsuite_name: STRING_8
			l_l: LIST [CLASS_I]
			l_ft: FEATURE_TABLE
			l_error: STRING_8
		do
			reset

			l_testsuite_name := "ALIAS_ANALYSIS_TESTSUITE"
			l_l := Eiffel_universe.classes_with_name (l_testsuite_name)
			inspect l_l.count
			when 1 then
				if attached l_l.first.compiled_class as c then
					stats_total.set_text ("0")
					stats_failures.set_text ("0")
					stats_ok.set_text ("0")
					from
						l_ft := c.feature_table
						l_ft.start
					until
						l_ft.after
					loop
						if l_ft.item_for_iteration.written_class = c then
							test_class (l_ft.item_for_iteration.type.base_class)
						end
						l_ft.forth
					end
				else
					l_error := "Class " + l_testsuite_name + " not compiled?!"
				end
			when 0 then
				l_error := "Class " + l_testsuite_name + " not found?!"
			else
				l_error := l_l.count.out + " " + l_testsuite_name + " classes found?!"
			end

			if l_error /= Void then
				expected.set_foreground_color (warning_text_color)
				expected.set_text (l_error)
			end
		end

	test_class (a_c: CLASS_C)
		require
			a_c /= Void
		local
			l_class_tree_item: EV_TREE_ITEM
			l_ft: FEATURE_TABLE
		do
			create l_class_tree_item.make_with_text (a_c.name)
			overview.extend (l_class_tree_item)

			from
				l_ft := a_c.feature_table
				l_ft.start
			until
				l_ft.after
			loop
				if
					attached {PROCEDURE_I} l_ft.item_for_iteration as p and then
					p.e_feature.written_class = a_c
				then
					test_feature (p)
				end
				{ISE_RUNTIME}.check_assert (False).do_nothing
				l_ft.forth
				{ISE_RUNTIME}.check_assert (True).do_nothing
			end

			if l_class_tree_item.is_expanded then
				l_class_tree_item.set_pixmap (fail_icon)
			else
				l_class_tree_item.set_pixmap (ok_icon)
			end
		end

	test_feature (a_f: PROCEDURE_I)
		require
			a_f /= Void
		local
			l_feature_tree_item, l_test_tree_item: EV_TREE_ITEM
			l_analyzer: ALIAS_ANALYSIS_RUNNER
			l_test_info: like test_info
		do
			if attached expected_aliasing (a_f) as l_expected_list then
				create l_feature_tree_item.make_with_text (a_f.feature_name_32)
				l_feature_tree_item.set_pixmap (ok_icon)
				overview.last.extend (l_feature_tree_item)

				create l_analyzer.make (a_f, Void, Void)
				across l_expected_list as c loop
					l_analyzer.step_until (c.item.index)
					l_test_info := [True, c.item.aliasing, l_analyzer.as_string]
					l_test_info.passed := l_test_info.expected.is_equal (l_test_info.actual)

					create l_test_tree_item.make_with_text (c.item.index.out)
					l_test_tree_item.set_data (l_test_info)
					if l_test_info.passed then
						l_test_tree_item.set_pixmap (ok_icon)
						stats_ok.set_text ((stats_ok.text.to_integer_32 + 1).out)
					else
						l_test_tree_item.set_pixmap (fail_icon)
						stats_failures.set_text ((stats_failures.text.to_integer_32 + 1).out)
					end
					l_feature_tree_item.extend (l_test_tree_item)
					stats_total.set_text ((stats_total.text.to_integer_32 + 1).out)

					if not l_test_info.passed and not l_feature_tree_item.is_expanded then
						l_feature_tree_item.set_pixmap (fail_icon)
						l_feature_tree_item.expand
					end
				end
			end
		end

	expected_aliasing (a_f: PROCEDURE_I): LIST [TUPLE [index: INTEGER_32; aliasing: STRING_8]]
		require
			a_f /= Void
		local
			l_error: STRING_8
			l_note_key, l_index_str: STRING_8
			l_index: INTEGER_32
			l_aliasing: STRING_8
		do
			if a_f.e_feature.ast.indexes /= Void then
				create {TWO_WAY_LIST [TUPLE [INTEGER_32, STRING_8]]} Result.make
				across
					a_f.e_feature.ast.indexes as c
				until
					l_error /= Void
				loop
					l_note_key := c.item.tag.name_8
					if l_note_key.starts_with ("aliasing") then
						l_index_str := l_note_key.substring(("aliasing").count + 1, l_note_key.count)
						if l_index_str.is_empty then
							l_index := a_f.number_of_breakpoint_slots
						elseif l_index_str.is_integer_32 then
							l_index := l_index_str.to_integer_32
						else
							l_error := "Note %"" + l_note_key + "%" has an invalid index (" + l_index_str + ")"
						end
						if l_error = Void then
							if
								l_index >= 1 and
								l_index <= a_f.number_of_breakpoint_slots and
								(Result.is_empty or else Result.last.index < l_index)
							then
								inspect c.item.index_list.count
								when 1 then
									l_aliasing := c.item.index_list[1].string_value_32
									if l_aliasing.starts_with ("%"") and l_aliasing.ends_with ("%"") then
										l_aliasing := l_aliasing.substring (2, l_aliasing.count - 1)
										l_aliasing.replace_substring_all ("%%N", "%N")
										Result.extend ([l_index, l_aliasing])
									else
										l_error := "Note %"" + l_note_key + "%" has an invalid value"
									end
								when 0 then
									l_error := "Note %"" + l_note_key + "%" has no values"
								else
									l_error := "Note %"" + l_note_key + "%" has " + c.item.index_list.count.out + " values"
								end
							else
								l_error := "Note %"" + l_note_key + "%" has an invalid index (" + l_index.out + ")"
							end
						end
					end
				end
				if l_error /= Void then
					expected.set_foreground_color (warning_text_color)
					expected.append_text (a_f.written_class.name + "." + a_f.feature_name_32 + ": " + l_error + "?!%N")
					Result := Void
				elseif Result.is_empty then
					Result := Void
				end
			end
		ensure
			Result = Void or else not Result.is_empty
		end

note
	copyright: "Copyright (c) 1984-2016, Eiffel Software"
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
