./zig-out/bin/cmakefmt test/test.cmake &> test/test.actual.cmake
if cmp -s test/test.expected.cmake test/test.actual.cmake; then
    rm test/test.actual.cmake
else
    git diff --no-index test/test.expected.cmake test/test.actual.cmake
fi
echo "test/formatting OK"

./zig-out/bin/cmakefmt test/comment_after_cmd.cmake > /dev/null
echo "test/comment_after_cmd OK"
