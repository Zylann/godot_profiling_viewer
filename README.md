Profiling viewer
===================

![image](https://user-images.githubusercontent.com/1311555/71685235-97e28700-2d8f-11ea-910e-c2d079fc3e1f.png)

This is a viewer for dumps produced by a small profiler I wrote in C++: https://github.com/Zylann/godot_voxel/blob/master/util/zprofiling.h
It started as a simple "get time before, get time after" method, which I improved to be able to profile specific sections of my module, at minimal overhead.

Please note it is very rough at the moment, as it was only a quick-and-dirty tool for my own use so far.
