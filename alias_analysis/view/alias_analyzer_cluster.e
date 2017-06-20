note
	description: "The gui view of the alias analysis tool."
	legal: "See notice at end of class."
	status: "See notice at end of class."
	date: "$Date: 2015-11-19 18:10:50 +0300 (Thu, 19 Nov 2015) $"
	revision: "$Revision: 98119 $"

class
	ALIAS_ANALYZER_CLUSTER

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
			extend (feature_view.editor.widget)
		end

	reset
		do
			feature_view.editor.clear_window
		end

	class_to_analyse (class_: CLASS_C; actual_class_name: STRING)
			-- Apply alias analysis to all features of class `class_'
		local
			l_visitor: ALIAS_ANALYSIS_VISITOR
			routine: PROCEDURE_I
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
					and then attached {PROCEDURE_I} r.associated_class.feature_named_32 (r.name_32) as p
						-- TODO: To solve (EiffelBase2)
					and (class_.name ~ "V_BINARY_TREE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "subtree_twin"))
					and (class_.name ~ "V_BINARY_TREE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_GENERAL_SORTED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "extend"))
					and (class_.name ~ "V_GENERAL_SORTED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_GENERAL_SORTED_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "extend"))
					and (class_.name ~ "V_GENERAL_HASH_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "wipe_out"))
					and (class_.name ~ "V_GENERAL_HASH_TABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "V_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "test_insert_left"))
					and (class_.name ~ "V_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "reverse"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "reverse"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_left"))
					and (class_.name ~ "V_SORTED_SET_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "remove"))
					and (class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "reverse"))

						-- TUPLES / agents: not supported yet
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

						-- ADDRESS_CURRENT_AS -> not supported
					and (class_.name ~ "V_REFERENCE_HASHABLE" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "hash_code"))


						-- Weird problem: Eiffel gives VOID error when trying to access it
					and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "key"))
					and (class_.name ~ "V_SET_TABLE_ITERATOR" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "item"))

						-- passing as argument a deferred class
					and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prepend"))
					and (class_.name ~ "V_DOUBLY_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_at"))
					and (class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prepend"))
					and (class_.name ~ "V_LINKED_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "insert_at"))


					and (class_.name ~ "FLAT_ARRAY" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "do_if_with_index"))
					and (class_.name ~ "FLAT_ARRAY" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "do_all_with_index"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "ll_move"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "extend"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "merge_left"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "merge_right"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "put_front"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "put_left"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "put_right"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "ll_merge_right"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "ll_put_front"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "ll_put_right"))
--					and (class_.name ~ "FLAT_TWO_WAY_LIST" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "remove"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "has"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "index_of"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "sequential_has"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "sequential_index_of"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "sequential_occurrences"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "sequential_search"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "occurrences"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "is_equal"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "search"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "append"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "merge_left"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "merge_right"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prune"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "prune_all"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "ll_prune"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "copy"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "duplicate"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "new_cursor"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "do_all"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "do_if"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "for_all"))
					and (class_.name ~ "FLAT_LINKED_SET" implies not (class_.feature_table.features.at (i).e_feature.name_32 ~ "there_exists"))
					and not (class_.name ~ "FLAT_TWO_WAY_LIST")
					and not (class_.name ~ "FLAT_ARRAYED_LIST")
					and not (class_.name ~ "FLAT_ARRAYED_QUEUE")
					and not (class_.name ~ "FLAT_ARRAYED_SET")
					and not (class_.name ~ "FLAT_BINARY_TREE")
					and not (class_.name ~ "FLAT_BI_LINKABLE")
					and not (class_.name ~ "FLAT_BOUNDED_QUEUE")
					and not (class_.name ~ "FLAT_HASH_TABLE")
					and not (class_.name ~ "FLAT_HASH_TABLE_ITERATION_CURSOR")
					and not (class_.name ~ "FLAT_INDEXABLE_ITERATION_CURSOR")
					and not (class_.name ~ "FLAT_INTEGER_INTERVAL")
					and not (class_.name ~ "FLAT_LINKED_LIST")

					and not (class_.feature_table.features.at (i).e_feature.name_32 ~ "out")

				then
					print ("====Feature: ")
					print (class_.feature_table.features.at (i).e_feature.name_32)
					print ("==(")
					print (actual_class_name)
					print (")==========")
					io.new_line
					routine := p
					if class_.feature_table.features.at (i).e_feature.is_function implies not class_.feature_table.features.at (i).e_feature.type.actual_type.name.starts_with ("MML") then
						create l_visitor.make (routine, Void)
						routine.body.process (l_visitor)
						io.new_line
						print (l_visitor.alias_graph.to_string)
						io.new_line
						print (l_visitor.alias_graph.to_graph)
						io.new_line

							--								(create {EXECUTION_ENVIRONMENT}).launch (
							--									"echo %"" + l_visitor.alias_graph.to_graph + "%" | dot -Tpdf | okular - 2>/dev/null"
							--								)
					end
				end
				i := i + 1
			end
		end

	clusters (c: CLUSTER_I)
			-- Apply alias analysis to all classes in cluster `c' (including nested
			-- clusters)
		local
			l_visitor: ALIAS_ANALYSIS_VISITOR
			routine: PROCEDURE_I
			class_: CLASS_C
			i: INTEGER
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
						class_to_analyse (class_, cla.item.actual_class.name)
					end
				end
			end
			io.new_line
			io.new_line
			if attached c.sub_clusters as sc then
				across
					sc as clu
				loop
					clusters (clu.item)
				end
			end
		end

	on_stone_changed (a_stone: STONE)
		do
			reset
			print ("%N=================================================================%N")
			if attached {CLUSTER_STONE} a_stone as fs then
				clusters (fs.cluster_i)
			elseif attached {CLASSC_STONE} a_stone as c and then
				attached {CLASS_C} c.class_i.compiled_class as cla
			then
				if not cla.name.starts_with ("MML_")
					and not (cla.name ~ "V_STRING_INPUT")
					and not (cla.name ~ "V_DEFAULT") then
					if System.eiffel_universe.classes_with_name (cla.name).count = 1 then
						print ("Class being analysed: ")
						print (cla.name)
						print (": ")
						print (System.eiffel_universe.classes_with_name (cla.name).count)
						io.new_line
						io.new_line
						class_to_analyse (cla, cla.name)
					end
				end
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
