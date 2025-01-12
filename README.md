A formatter for CMake files written in Zig in around ~1300 LOC including tests, comments etc. It doesn't depend on anything except the zig std library. I mainly intended to learn zig when I started this. Its not very thoroughly tested so there are probably bugs lurking around in the code

### Build

```
zig build
```

### Usage
```
Usage:

 If no arguments are specified then input is taken from stdin

Overwrite the given file:
    cmakefmt -i CMakeLists.txt

Write to stdout:
    cmakefmt CMakeLists.txt

Options:
 -i   Overwite the given file (inplace formatting)
 -h   Print this help text
```

Thanks to [gersemi](https://github.com/BlankSpruce/gersemi/) formatter, I used some of its tests to ensure correctness.

### LICENSE
- MIT
