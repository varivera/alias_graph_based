note
	description: "Summary description for {APPLICATION}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

create
	make

feature

	l: V_LINKED_LIST [STRING]
	s: STRING

	make
		do
			create l
			s := ""
		end

	t 
		do
			l.put (s, 1)
		end



end
