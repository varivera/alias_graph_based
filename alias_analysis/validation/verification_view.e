note
	description: "The gui view of all tools."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-19 18:10:50 +0300 (Thu, 19 Nov 2015) $"
	revision: "$Revision: 98119 $"

class
	VERIFICATION_VIEW

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

	info_text: EV_TEXT

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
			create info_text
			info_text.disable_edit
			extend (feature_view.editor.widget)
			extend (info_text)
		end

	reset
		do
			feature_view.editor.clear_window
			info_text.set_text ("")
		end

	on_stone_changed (a_stone: STONE)
		local
			l_result: STRING
		do
			reset
			l_result := ""
			print ("%N=================================================================%N")
			if attached {CLUSTER_STONE} a_stone as fs then
				do_nothing
			elseif attached {FEATURE_STONE} a_stone as fs and then attached {E_ROUTINE} fs.e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine then
					--feature_view.set_stone (a_stone)
				do_nothing
			elseif attached {CLASSC_STONE} a_stone as c and then attached {CLASS_C} c.class_i.compiled_class as cla then
				if not cla.name.starts_with ("MML_") and not (cla.name ~ "V_STRING_INPUT") and not (cla.name ~ "V_DEFAULT") then
					if System.eiffel_universe.classes_with_name (cla.name).count = 1 then
						class_to_analyse (cla, cla.name, l_result)
					end
				end
			end
			info_text.set_text (l_result)
		end

	class_to_analyse (class_: CLASS_C; actual_class_name, a_result: STRING)
			-- different analysis
		local
			mq: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- mapping from MQ to class attributes
			atts_mod: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- set of modified attributes per feature in class `class_'
			mc: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]
				-- set of modify clauses per feature in class `class_'
		do
			print ("VERIFICATION Analysis%N")
			a_result.append ("Class: ")
			a_result.append (class_.name)
			a_result.append ("%NMap MQ to Class Attributes%N")

				-- 1)
			create mq.make (0)
			map_mq_to_atts (class_, actual_class_name, mq)
			a_result.append (map_to_string (mq))

				-- 2)
			create atts_mod.make (0)
			create mc.make (0)
			change_modify (class_, actual_class_name, atts_mod, mc)
			a_result.append ("%NModified Class Attributes%N")
			a_result.append (atts_mod_to_string (atts_mod))
		end

	map_mq_to_atts (class_: CLASS_C; actual_class_name: STRING; mq: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
			-- it stores the map between Model Queries and Class Attributes for class `class_id'
		local
			l_visitor: MQ_ANALYSIS_VISITOR
		do
			if attached class_.ast.top_indexes as top_indexes then
				across
					top_indexes as i
				loop
					if i.item.tag.name_32 ~ "model" then
						across
							i.item.index_list as ii
						loop
							print (ii.item.string_value_32)
							io.new_line
							if class_.feature_named_32 (ii.item.string_value_32).is_attribute then
								mq.force (create {TWO_WAY_LIST [STRING]}.make, ii.item.string_value_32)
								mq [ii.item.string_value_32].force (ii.item.string_value_32)
							elseif attached {E_ROUTINE} class_.feature_named_32 (ii.item.string_value_32).e_feature as r and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine and then r.is_function then
								if not r.is_deferred and then r.type.actual_type.name.starts_with ("MML") then
									print ("Feature: " + ii.item.string_value_32)
									io.new_line
									create l_visitor.make (class_.class_id)
									routine.body.process (l_visitor)
									mq.force (l_visitor.mq_list, r.name_32)
								else
									mq.force (create {TWO_WAY_LIST [STRING]}.make, r.name_32)
									mq [r.name_32].force (r.name_32 + "*")
								end
							end
						end
					end
				end
			end
			across
				System.class_of_id (class_.class_id).parents_classes as p
			loop
				if p.item.name /~ "ANY" then
					map_mq_to_atts (p.item, p.item.name, mq)
				end
			end
		end


	change_modify (class_: CLASS_C; actual_class_name: STRING; atts_mod, mc: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
			-- stores the modified attributes per feature in class `class' and the set of modify mq it lists
		local
			i: INTEGER
		do

			print ("Analysis%N")
			from
				i := 1
			until
				i > class_.feature_table.count or class_.is_deferred
			loop
				if not class_.feature_table.features.at (i).is_attribute
					and class_.feature_table.features.at (i).e_feature.associated_class.class_id = class_.class_id
					and attached {E_ROUTINE} class_.feature_table.features.at (i).e_feature as r
					and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as routine
				then
					-- feature with issues
					if (class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "test_prepend"))
						and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "extend_at"))
						and (class_.name ~ "V_BINARY_TREE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "subtree_twin"))
						and (class_.name ~ "V_BINARY_TREE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
						and (class_.name ~ "V_GENERAL_SORTED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
						and (class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
						and (class_.name ~ "V_GENERAL_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
						and (class_.name ~ "V_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
						and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "reverse"))
						and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "reverse"))
						and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
						and (class_.name ~ "V_SORTED_SET_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "remove"))
						and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "extend"))
						and (class_.name ~ "V_HASH_SET_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "search"))
						and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "make_at_key"))
						and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "search_key"))
						and (class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "less_equal"))
						and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "item"))
						and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "at"))
						and (class_.name ~ "V_GENERAL_SORTED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "less_equal"))
						and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_one"))
						and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_one_predicate"))
						and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_two"))
						and (class_.name ~ "V_TUPLE_PROJECTOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "project_two_predicate"))
						and (class_.name ~ "V_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "default_create"))
						and (class_.name ~ "V_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "default_create"))
						and (class_.name ~ "V_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "with_object_equality"))
						and (class_.name ~ "V_GENERAL_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "make"))
						and (class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "make"))
						and (class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "key_equivalence"))
						and (class_.name ~ "V_REFERENCE_HASHABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "hash_code"))
						and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
						and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "key"))
						and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "item"))
						and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prepend"))
						and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_at"))
						and (class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prepend"))
						and (class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_at"))
						and not (class_.feature_table.features.at (i).e_feature.name_32 ~ "out")
					then
						print ("====Feature: ")
						print (class_.feature_table.features.at (i).e_feature.name_32)
						print ("==(")
						print (actual_class_name)
						print (")==========")
						io.new_line

						if class_.feature_table.features.at (i).e_feature.is_function implies not class_.feature_table.features.at (i).e_feature.type.actual_type.name.starts_with ("MML") then
							change_analysis (routine, atts_mod)


							modify_clause (routine, class_.class_id, mc)
						end
					end
				end
				i := i + 1
			end
		end

	change_analysis (routine: PROCEDURE_I; atts_mod: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
		local
			l_visitor: ALIAS_ANALYSIS_VISITOR
		do
			create l_visitor.make (routine, Void)
			routine.body.process (l_visitor)
			atts_mod.force (l_visitor.alias_graph.change_atts, routine.e_feature.name_32)
		end

	modify_clause (routine: PROCEDURE_I; class_id: INTEGER; mc: HASH_TABLE [TWO_WAY_LIST [STRING], STRING])
		local
			modify: MODIFY_CLAUSES_VISITOR
		do
			create modify.make (class_id, routine.e_feature.name_32)
			routine.body.process (modify)

			mc.force (modify.modify_clause_list, routine.e_feature.name_32)

		end

	map_to_string (res: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): STRING
		do
			Result := ""
			across
				res as mq
			loop
				if mq.item.count > 0 then
					Result := Result + "     " + mq.key + ": ["
					across
						mq.item as att
					loop
						Result := Result + att.item
						if not att.is_last then
							Result := Result + ", "
						end
					end
					Result := Result + "]"
				end
				Result := Result + "%N"
			end
		end

	atts_mod_to_string (res: HASH_TABLE [TWO_WAY_LIST [STRING], STRING]): STRING
		do
			Result := ""
			across
				res as feat
			loop
				Result := Result + feat.key + ": ["
				across
					feat.item as atts
				loop
					Result := Result + atts.item
					if not atts.is_last then
						Result := Result + ", "
					end
				end
				Result := Result + "]%N"
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
