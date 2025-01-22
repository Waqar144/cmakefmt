./zig-out/bin/cmakefmt test/test.cmake &> test/test.actual.cmake
if cmp -s test/test.expected.cmake test/test.actual.cmake; then
    rm test/test.actual.cmake
    echo "test/formatting OK"
else
    git diff --no-index test/test.expected.cmake test/test.actual.cmake
    echo "test/formatting FAIL"
fi

./zig-out/bin/cmakefmt test/comment_after_cmd.cmake > /dev/null
echo "test/comment_after_cmd OK"

./zig-out/bin/cmakefmt test/test.crlf.cmake &> test/test.crlf.actual.cmake
if cmp -s test/test.crlf.expected.cmake test/test.crlf.actual.cmake; then
    rm test/test.crlf.actual.cmake
    echo "test/crlf OK"
else
    echo "test/crlf FAIL"
    git diff --no-index test/test.crlf.expected.cmake test/test.crlf.actual.cmake
fi
