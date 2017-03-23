class
	ALIAS_OBJECT_INFO

inherit

	ANY
		redefine
			out
		select
			out
		end

	TRACING
		rename out as out_tracing end

create
	make_variable, make_object, make_void

feature {NONE}

	make_variable (a_context_routine: PROCEDURE_I; a_variable_map: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING_8]; a_variable_name: STRING_8)
		require
			a_context_routine /= Void
			a_variable_map /= Void
			a_variable_name /= Void
		do
			context_routine := a_context_routine
			variable_map := a_variable_map
			if tracing then
				print_atts_depth (variable_map)
			end
			variable_name := a_variable_name
			alias_object := a_variable_map [a_variable_name]
		ensure
			context_routine = a_context_routine
			variable_map = a_variable_map
			variable_name = a_variable_name
			alias_object = a_variable_map [a_variable_name]
		end

	make_object (a_alias_object: TWO_WAY_LIST [ALIAS_OBJECT])
		require
			a_alias_object /= Void
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
		do
			create l_obj.make
			across
				a_alias_object as objects
			loop
				l_obj.force (objects.item)
			end
			alias_object := l_obj
		ensure
				--	alias_object.has (a_alias_object)
		end

	make_void
		do
		end

feature -- {NONE}

	context_routine: PROCEDURE_I

	variable_map: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING_8]

feature

	variable_name: STRING_8

	function: BOOLEAN
			-- was this ALIAS_OBJECT_INFO created by analysing a function?

feature {ANY}

	alias_object: TWO_WAY_LIST [ALIAS_OBJECT] assign set_alias_object

	is_variable: BOOLEAN
		do
			Result := variable_map /= Void
		end

	set_alias_object (a_alias_object: TWO_WAY_LIST [ALIAS_OBJECT])
		require
			is_variable
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
		do
			if attached alias_object as objs and then objs.first.type.is_expanded then
					-- do not perform any action if the object is expanded

			elseif a_alias_object = Void then
				alias_object := Void
				variable_map.remove (variable_name)
			else
				a_alias_object.start
				if a_alias_object.item.type.is_expanded then
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (a_alias_object.item.type))
					alias_object := l_obj
					variable_map [variable_name] := alias_object
						--				across
						--					a_alias_object.attributes as c
						--				loop
						--					-- VIC (05.08.16): what does the next line do?
						--					--What does this loop do?
						--					(create {ALIAS_OBJECT_INFO}.make_variable (context_routine, -- wrong; unused dummy
						-- alias_object.attributes, c.key)).alias_object := c.item
						--				end
				else
					create l_obj.make
					across
						a_alias_object as aliases
					loop
						if not attached {VOID_AS} aliases.item then
							l_obj.force (aliases.item)
						elseif alias_object.first.type.has_detachable_mark then
							l_obj.force (aliases.item)
						end
					end
					alias_object := l_obj
						--alias_object := a_alias_object
						--print_atts (variable_map)
					if tracing then
						print_atts_depth (variable_map)
					end
					variable_map [variable_name] := l_obj
					if tracing then
						print_atts_depth (variable_map)
					end
				end
			end
		end

	set_function
			-- assigns True to function
		do
			function := True
		end

	type: TYPE_A
		require
			is_variable
		local
			l_context: AST_CONTEXT
			l_type_checker: AST_FEATURE_CHECKER_GENERATOR
			l_type: TYPE_A
		do
			if variable_name.is_equal ("Result") then
					-- Result
				l_type := context_routine.type
			elseif attached context_routine.written_class.feature_named_32 (variable_name) as l_tmp then
					-- attribute
				l_type := l_tmp.type
			elseif attached argument_type as l_tmp then
					-- argument
				l_type := l_tmp
			else
					-- local variable
				l_context := (create {SHARED_AST_CONTEXT}).context
				l_context.clear_all
				l_context.initialize (context_routine.written_class, context_routine.written_class.actual_type)
				l_context.set_written_class (context_routine.written_class)
				l_context.set_current_feature (context_routine)
				create l_type_checker
				l_type_checker.init (l_context)
				l_type_checker.type_check_only (context_routine, True, False, context_routine.is_replicated)
				l_type := l_context.locals.item ((create {SHARED_NAMES_HEAP}).names_heap.id_of (variable_name)).type
				l_context.clear_all
			end
			if attached {CL_TYPE_A} l_type as l_tmp then
				Result := l_tmp
			elseif attached {FORMAL_A} l_type as l_tmp then
				Result := l_tmp
			elseif attached {LIKE_CURRENT} l_type as l_tmp then
				create {CL_TYPE_A} Result.make (context_routine.written_class.class_id)
			else
				Io.put_string ("Unkown type: " + l_type.generator + "%N")
			end
		end

	map (name: STRING): TWO_WAY_LIST [ALIAS_OBJECT]
			-- returns the alias_object associated to `name'
		do
			create Result.make
			across
				variable_map.at (name) as vals
			loop
				Result.force (vals.item)
			end
		end

feature {NONE}

	argument_type: TYPE_A
		local
			l_i, l_count: INTEGER_32
		do
			from
				l_i := 1
				l_count := context_routine.argument_count
			until
				l_i > l_count or Result /= Void
			loop
				if context_routine.arguments.item_name (l_i).is_equal (variable_name) then
					Result := context_routine.arguments.i_th (l_i)
				end
				l_i := l_i + 1
			end
		end

feature --Redefinition

	out: STRING_8
		do
			Result := "%Nvariable_name: "
			Result := Result + variable_name
			Result := Result + "%Nalias_object: "
			if attached alias_object then
				across
					alias_object as ao
				loop
					Result := Result + ao.item.out2 + " - "
				end
			else
				Result := Result + "Void "
			end
			Result := Result + "%Nalias_object: "
			Result := Result + "%Nvariable_map:%N"
			across
				variable_map as var
			loop
				Result := Result + "key: "
				Result := Result + var.key
				across
					var.item as i
				loop
					Result := Result + i.item.out2
					Result := Result + "%N"
				end
				Result := Result + "%N==%N"
			end
		end

feature -- Todelete

	print_atts_depth (c: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING_8])
		do
			if tracing then
				print ("Atts Deep%N")
				print_atts_depth_help (c, 1)
				reset (c)
				print ("-------------------------------------------------%N")
			end
		end

	reset (in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING_8])
		do
			across
				in as links
			loop
				across
					links.item as vals
				loop
					if vals.item.visited then
						vals.item.visited := false
						reset (vals.item.attributes)
					end
				end
			end
		end

	print_atts_depth_help (in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], STRING_8]; i: INTEGER)
		local
			tab: STRING
		do
			if tracing then
				create tab.make_filled (' ', i)
				across
					in as links
				loop
					print (tab)
					print (links.key + ": [")
					across
						links.item as vals
					loop
						print (vals.item.out2)
						print (":")
						io.new_line
						if not vals.item.visited then
							vals.item.visited := true
							print_atts_depth_help (vals.item.attributes, i + 2)
						end
					end
					print (tab)
					print ("]")
					io.new_line
					io.new_line
				end
			end
		end

invariant
		--VIC: (context_routine = Void) = (variable_map = Void) = (variable_name = Void)
		-- counter example: all of them are not Void, the assertion will give False
	(context_routine = Void) = (variable_map = Void) and then (variable_map = Void) = (variable_name = Void) and then (context_routine = Void) = (variable_name = Void)

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
