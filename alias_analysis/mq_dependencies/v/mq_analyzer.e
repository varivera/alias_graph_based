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
		select
			is_equal,
			default_create,
			copy
		end

	SHARED_SERVER
		rename
			is_equal as is_equal_shared,
			default_create as default_create_shared,
			copy as copy_shared
		end

create
	make

feature {NONE}

	feature_view: EB_ROUTINE_FLAT_FORMATTER

	mq_info_text: EV_TEXT

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
		end

	on_stone_changed (a_stone: STONE)
		local
			l_result: STRING
		do
			reset
			l_result := ""
			print ("%N=================================================================%N")
			if attached {CLUSTER_STONE} a_stone as fs then
				clusters (fs.cluster_i, l_result)
			elseif attached {FEATURE_STONE} a_stone as fs and then attached {E_ROUTINE} fs.e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
					--feature_view.set_stone (a_stone)
				{ISE_RUNTIME}.check_assert (False).do_nothing
				feature_view.set_stone (fs)
				{ISE_RUNTIME}.check_assert (True).do_nothing
				run_mq_analysis (routine, routine.access_class.actual_type.class_id, l_result)
			elseif attached {CLASSC_STONE} a_stone as c and then attached {CLASS_C} c.class_i.compiled_class as cla then
				if not cla.name.starts_with ("MML_") and not (cla.name ~ "V_STRING_INPUT") and not (cla.name ~ "V_DEFAULT") then
					if System.eiffel_universe.classes_with_name (cla.name).count = 1 then
						class_to_analyse (cla, cla.name, l_result)
					end
				end
			end


			mq_info_text.set_text (l_result)
		end

	clusters (c: CLUSTER_I; a_result: STRING)
			-- Apply MQ analysis to all classes in cluster `c' (including nested
			-- clusters)
		local
			class_: CLASS_C
		do
			print (c.cluster_name)
			io.new_line
			io.new_line
			across
				c.classes as cla
			loop
				if not cla.item.actual_class.name.starts_with ("MML_") and not (cla.item.actual_class.name ~ "V_STRING_INPUT") and not (cla.item.actual_class.name ~ "V_DEFAULT") then
					if System.eiffel_universe.classes_with_name (cla.item.actual_class.name).count = 1 then
						print ("Class being analysed: ")
						print (cla.item.actual_class.name)
						print (": ")
						print (System.eiffel_universe.classes_with_name (cla.item.actual_class.name).count)
						io.new_line
						io.new_line
						class_ := System.eiffel_universe.classes_with_name (cla.item.actual_class.name).first.compiled_class
						class_to_analyse (class_, cla.item.actual_class.name, a_result)
					end
				end
			end
			io.new_line
			io.new_line
			if attached c.sub_clusters as sc then
				across
					sc as clu
				loop
					clusters (clu.item, a_result)
				end
			end
		end

	class_to_analyse (class_: CLASS_C; actual_class_name, a_result: STRING)
			-- Apply mq analysis to all features of class `class_'
		do
			print ("Analysis%N")
			a_result.append ("Class: ")
			a_result.append (class_.name)
			a_result.append ("%N%N")

			across
				class_.ast.top_indexes as i
			loop
				if i.item.tag.name_32 ~ "model" then
					across
						i.item.index_list as ii
					loop
						if class_.feature_named_32 (ii.item.string_value_32).is_attribute then
							a_result.append (ii.item.string_value_32+": "+ii.item.string_value_32+"%N")
						elseif attached {E_ROUTINE} class_.feature_named_32 (ii.item.string_value_32).e_feature as r
							and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine
							and then r.is_function and then r.type.actual_type.name.starts_with ("MML")
							and then not r.is_deferred
						then
							print ("Feature: " +  ii.item.string_value_32 )
							io.new_line
							run_mq_analysis (routine, class_.class_id, a_result)
						end

					end
				end
			end
			a_result.append ("%N%N")

		end

	run_mq_analysis (routine: PROCEDURE_I; class_id: INTEGER; a_result: STRING)
		local
			l_visitor: MQ_ANALYSIS_VISITOR
		do
			create l_visitor.make (class_id)
			routine.body.process (l_visitor)
			a_result.append (routine.e_feature.name_32)
			a_result.append (": [")
			across
				l_visitor.mq_list as atts
			loop
				a_result.append (atts.item)
				if atts.is_last then
					a_result.append ("]%N")
				else
					a_result.append (", ")
				end
			end
			if l_visitor.mq_list.count = 0 then
				a_result.append ("]%N")
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
