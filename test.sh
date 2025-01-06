./zig-out/bin/cmakeformat test/test.cmake &> test/test.actual.cmake
if cmp -s test/test.expected.cmake test/test.actual.cmake; then
    echo "test passed";
    rm test/test.actual.cmake
else
    echo "test failed";
    git diff --no-index test/test.expected.cmake test/test.actual.cmake
fi
