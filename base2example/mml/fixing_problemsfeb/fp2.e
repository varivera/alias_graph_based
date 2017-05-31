note
	description: "Summary description for {FP2}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	FP2
create
	make

feature
	make
		do
			d := ""
		end
	h_issue3 (i,j: INTEGER)
		do

		end
	d: STRING
	plus alias "+" (other: FP2): STRING
		do
			Result := other.d
		end

end
