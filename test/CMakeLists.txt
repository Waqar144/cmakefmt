cmake_minimum_required(VERSION 3.12)

project(proj)



#[[This is a bracket comment.
It runs until the close bracket.]]

#[[comment big]] #line
add_executable(my_exe
    asd.cpp
    kkk.cpp
    lll.cpp
    value.cpp
)

if (WIN32)
message("helo")
endif()

message("This is a quoted argument containing multiple lines.
This is always one argument even though it contains a ; character.
Both \\-escape sequences and ${variable} references are evaluated.
The text does not end on an escaped double-quote like \".
It does end in an unescaped double quote.
")


message([=[
This is the first line in a bracket argument with bracket length 1.
No \-escape sequences or ${variable} references are evaluated.
This is always one argument even though it contains a ; character.
The text does not end on a closing bracket of length 0 like ]].
It does end in a closing bracket of length 1.
]=])
