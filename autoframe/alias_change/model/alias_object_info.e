note
	description: "[
		Alias Object Info is meta information about the object being analysed.
		It is necessary for the construction of the alias graph
	]"
	date: "August, 2018"
	author: "Victor Rivera"


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

	make_variable (a_context_routine: PROCEDURE_I; a_variable_map: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]; a_variable_name: STRING_8)
		require
			a_context_routine /= Void
			a_variable_map /= Void
			a_variable_name /= Void
		do
			context_routine := a_context_routine
			variable_map := a_variable_map
			variable_name := a_variable_name
			alias_object := a_variable_map [create {ALIAS_KEY}.make (a_variable_name)]
		ensure
			context_routine = a_context_routine
			variable_map = a_variable_map
			variable_name = a_variable_name
			alias_object = a_variable_map [create {ALIAS_KEY}.make (a_variable_name)]
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
			-- routine that makes the object call

	variable_map: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]
			-- map of object computations of the current object (basically the object's class atts)

feature

	variable_name: STRING_8
			-- entity name

	function: BOOLEAN
			-- was this ALIAS_OBJECT_INFO created by analysing a function?

	switch: INTEGER
		-- switch is used to determine the different ways of
		--	of setting alias objects



feature {ANY}

	alias_object: TWO_WAY_LIST [ALIAS_OBJECT] assign set_alias_object
			-- the actual object. It is a list since it is possible
			-- that the same entity is used to hold different object e.g
			-- after the execution of
			--			if C then
			--				v := w
			--			else
			--				v := y
			--			end
			-- variable 'v' is associated to alias_object(w) and alias_object(y)

	is_variable: BOOLEAN
		do
			Result := variable_map /= Void
		end

	set_alias_object (a_alias_object: TWO_WAY_LIST [ALIAS_OBJECT])
		require
			is_variable
			switch /= 0
		local
			l_obj: TWO_WAY_LIST [ALIAS_OBJECT]
			k: ALIAS_KEY
		do
			no_formal (a_alias_object)

			if attached alias_object as objs and then objs.first.type.is_expanded then
					-- do not perform any action if the object is expanded

			elseif a_alias_object = Void then
				--alias_object := Void
				--variable_map.remove (variable_name)
				create l_obj.make
				l_obj.force (create {ALIAS_OBJECT}.make_void)
				alias_object := l_obj
				variable_map [create {ALIAS_KEY}.make (variable_name)] := l_obj
			else
				a_alias_object.start
				if a_alias_object.item.type.is_expanded then
					create l_obj.make
					l_obj.force (create {ALIAS_OBJECT}.make (a_alias_object.item.type))
					alias_object := l_obj
					variable_map [create {ALIAS_KEY}.make (variable_name)] := alias_object
						--				across
						--					a_alias_object.attributes as c
						--				loop
						--					-- VIC (05.08.16): what does the next line do?
						--					--What does this loop do?
						--					(create {ALIAS_OBJECT_INFO}.make_variable (context_routine, -- wrong; unused dummy
						-- alias_object.attributes, c.key)).alias_object := c.item
						--				end
				else
					create k.make (variable_name)
					create l_obj.make
					across
						a_alias_object as aliases
					loop
						if not attached {VOID_AS} aliases.item then
							l_obj.force (aliases.item)
						elseif alias_object.first.type.has_detachable_mark then
							l_obj.force (aliases.item)
						end
							-- update predecessors
						if switch = 3 then
							if not aliases.item.predecessors_param.has (k) then
								aliases.item.predecessors_param.force (create {TWO_WAY_LIST [ALIAS_VISITABLE]}.make, k)
							end

							across
								alias_object.first.predecessors.at (k) as pred
							loop
								if across aliases.item.predecessors_param.at (k) as p all p.item /~ pred.item end then
									aliases.item.predecessors_param.at (k).force (pred.item)
								end
							end
						else
							if not aliases.item.predecessors.has (k) then
								aliases.item.predecessors.force (create {TWO_WAY_LIST [ALIAS_VISITABLE]}.make, k)
							end

							across
								alias_object.first.predecessors.at (k) as pred
							loop
								if across aliases.item.predecessors.at (k) as p all p.item /~ pred.item end then
									aliases.item.predecessors.at (k).force (pred.item)
								end
							end
						end
					end
					if variable_name ~ "items" and then switch = 1 then
							-- items is a special attribute of V_SPECIAL
						across
							l_obj as l_ao
						loop
							if across alias_object as ao all ao.item /~ l_ao.item end then
								alias_object.force (l_ao.item)
							end
						end
					else
						alias_object := l_obj
					end

						--alias_object := a_alias_object
					variable_map [k] := alias_object
				end
			end
			switch := 0
		ensure
			switch = 0
		end

	set_direct_alias_object (a_alias_object: TWO_WAY_LIST [ALIAS_OBJECT])
		require
			is_variable
		do
			alias_object := a_alias_object
		end

	no_formal (a_alias_object: TWO_WAY_LIST [ALIAS_OBJECT])
			--precheck: no FORMAL_A
			-- premise: if a_alias_object contains a FORMAL_A then it is not aliased.
				-- 		-> remove it and create a new one with current.alias_object type
		do
			from
				a_alias_object.start
			until
				a_alias_object.after
			loop
				if attached {FORMAL_A} a_alias_object.item.type then
					a_alias_object.item.set_type (alias_object.first.type)
				end
				a_alias_object.forth
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
			elseif attached {LIKE_FEATURE} l_type as l_tmp then
				Result := l_tmp.actual_type
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
				variable_map.at (create {ALIAS_KEY}.make (name)) as vals
			loop
				Result.force (vals.item)
			end
		end

	set_switch_normal
		do
			switch := 1
		end

	set_swicth_special_no_direct
		do
			switch := 2
		end

	set_swicth_param
		do
			switch := 3
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
				Result := Result + var.key.name
				across
					var.item as i
				loop
					Result := Result + i.item.out2
					Result := Result + "%N"
				end
				Result := Result + "%N==%N"
			end
		end

feature -- For Debugging purposes

	print_atts_depth (c: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
		do
			if tracing then
				print ("Atts Deep%N")
				print_atts_depth_help (c, 1)
				reset (c)
				print ("-------------------------------------------------%N")
			end
		end

	reset (in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY])
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

	print_atts_depth_help (in: HASH_TABLE [TWO_WAY_LIST [ALIAS_OBJECT], ALIAS_KEY]; i: INTEGER)
		local
			tab: STRING
		do
			if tracing then
				create tab.make_filled (' ', i)
				across
					in as links
				loop
					print (tab)
					print (links.key.name + ": [")
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
	(switch = 0 or switch = 1 or switch = 2 or switch = 3)

note
	copyright: "Copyright (c) 1984-2018, Eiffel Software"
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
