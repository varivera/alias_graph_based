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
			l_result: HASH_TABLE [HASH_TABLE [ TWO_WAY_LIST [STRING], STRING], STRING]
		do
			reset
			create l_result.make (0)
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


			mq_info_text.set_text (to_string (l_result))
		end

	clusters (c: CLUSTER_I; a_result: HASH_TABLE [HASH_TABLE [ TWO_WAY_LIST [STRING], STRING], STRING])
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

	class_to_analyse (class_: CLASS_C; actual_class_name: STRING; a_result: HASH_TABLE [HASH_TABLE [ TWO_WAY_LIST [STRING], STRING], STRING])
			-- Apply mq analysis to all features of class `class_'
		do
			print ("Analysis%N")

			if not a_result.has (actual_class_name) then
				a_result.force (create {HASH_TABLE [ TWO_WAY_LIST [STRING], STRING]}.make (1), actual_class_name)
			end

			across
				class_.ast.top_indexes as i
			loop
				if i.item.tag.name_32 ~ "model" then
					across
						i.item.index_list as ii
					loop
						print (ii.item.string_value_32)
						io.new_line

						if attached {E_ROUTINE} class_.feature_named_32 (ii.item.string_value_32).e_feature as r
							and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
							print (r.is_function)
						end
						if class_.feature_named_32 (ii.item.string_value_32).is_attribute then

							if not a_result.has (actual_class_name) then
								a_result.force (create {HASH_TABLE [ TWO_WAY_LIST [STRING], STRING]}.make (1), actual_class_name)
								a_result [actual_class_name].force (create {TWO_WAY_LIST [STRING]}.make, ii.item.string_value_32)

							elseif not a_result [actual_class_name].has (ii.item.string_value_32) then
								a_result [actual_class_name].force (create {TWO_WAY_LIST [STRING]}.make, ii.item.string_value_32)
							end
							(a_result [actual_class_name])[ii.item.string_value_32].force (ii.item.string_value_32)
						elseif attached {E_ROUTINE} class_.feature_named_32 (ii.item.string_value_32).e_feature as r
							and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine
							and then r.is_function
						then
							if not r.is_deferred and then r.type.actual_type.name.starts_with ("MML") then
								print ("Feature: " +  ii.item.string_value_32 )
								io.new_line
								run_mq_analysis (routine, class_.class_id, a_result)
							else
								if not a_result.has (actual_class_name) then
									a_result.force (create {HASH_TABLE [ TWO_WAY_LIST [STRING], STRING]}.make (1), actual_class_name)
									a_result [actual_class_name].force (create {TWO_WAY_LIST [STRING]}.make, r.name_32)
								elseif not a_result [actual_class_name].has (ii.item.string_value_32) then
									a_result [actual_class_name].force (create {TWO_WAY_LIST [STRING]}.make, r.name_32)
								end
								(a_result [actual_class_name])[r.name_32].force (r.name_32+"*")
							end

						end

					end
				end
			end

			across
				System.class_of_id (class_.class_id).parents_classes as p
			loop
				if p.item.name /~ "ANY" then
					class_to_analyse (p.item,  p.item.name, a_result)
				end
			end
		end

	run_mq_analysis (routine: PROCEDURE_I; class_id: INTEGER; a_result: HASH_TABLE [HASH_TABLE [ TWO_WAY_LIST [STRING], STRING], STRING])
		local
			l_visitor: MQ_ANALYSIS_VISITOR
				-- for validation purposes: TODELETE
			modify: MODIFY_CLAUSES_VISITOR
		do
--			create l_visitor.make (class_id)
--			routine.body.process (l_visitor)

			--todelete
			create modify.make (class_id, routine.e_feature.name_32)
			routine.body.process (modify)
			print ("%N==========================%N")
			across
				modify.modify_clause_list as mc
			loop
				print (mc.item)
				io.new_line
			end
			print ("==========================%N")
			-- todelete
			if not a_result.has (routine.access_class.name) then
				a_result.force (create {HASH_TABLE [ TWO_WAY_LIST [STRING], STRING]}.make (1), routine.access_class.name)
				a_result [routine.access_class.name].force (l_visitor.mq_list, routine.e_feature.name_32)
			elseif not a_result [routine.access_class.name].has (routine.e_feature.name_32) then
				a_result [routine.access_class.name].force (l_visitor.mq_list, routine.e_feature.name_32)
			else
				across
					l_visitor.mq_list as atts
				loop
					if not across (a_result [routine.access_class.name])[routine.e_feature.name_32] as i all i.item /~ atts.item end then
						(a_result [routine.access_class.name])[routine.e_feature.name_32].force (atts.item)
					end
				end
			end

		end

	to_string (res: HASH_TABLE [HASH_TABLE [ TWO_WAY_LIST [STRING], STRING], STRING]): STRING
		do
			Result := ""

			across
				res as c
			loop
				if c.item.count > 0 then
					Result := Result + c.key + "%N"
					across
						c.item as mq
					loop
						if mq.item.count > 0 then
							Result := Result + "     " + mq.key + ": ["
							across
								mq.item as att
							loop
								Result := Result + att.item
								if not att.is_last then
									Result := Result + ", "
								else
									Result := Result + "]"
								end
							end
						end
					end
				end
				Result := Result + "%N"
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
