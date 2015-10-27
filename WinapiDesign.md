## Structure ##

The library publishes a procedural API that mimics the windows API and an object API for creating windows and controls. Both APIs share the same namespace, which is the table returned by `require'winapi'`.

Interactivity (windows message processing) is handled in the object layer since it requires keeping state. This means that there's no direct procedural API to assign event callbacks to controls. Dispatching of messages to child controls is implemented in the object layer. The object layer also provides additional features like anchor-based layouting, so there's little reason to use the procedural API directly except for say, implementing a different object API.

## Scope ##

Current work is based on the windows 7 SDK headers, the latest available headers from Microsoft. Constants, macros, typedefs and function prototypes for all platforms from Windows 2000/XP on (version 0x0500 that is) are included. Obsolete ones are not included. Only wide-char API variants are included, the ANSI variants are not included. Only controls from `ComCtl32.dll` version 6 available on Windows XP and above are supported. To be able to use comctl 6, you'll need a manifest file near your `luajit.exe` (included). Note: comctl 6 is Unicode only, another reason not to bind the ANSI API.

## The code ##

The code is a 4-layer cake that looks like this:
  * object API - actual classes for windows and controls (all files named `*class.lua`)
  * OO system - mechanism for inheritance, instantiation and virtual properties
  * procedural API - actual winapi wrappers
  * ffi layer - helper functions to aid wrapping

The first line in each file is a comment classifying the file and describing its topic.

## Object API ##

The object API is implemented in terms of a minimalist OO system implemented in `class.lua`, `object.lua`, and `vobject.lua`. The OO system features single inheritance, constructors, and virtual properties with getters and setters. It differentiates between class (derivation) and object (instantiation), so it's not a prototype-based system.

Winapi classes are implemented one-per-file in `*class.lua` and start with `basewindowclass.lua` which contains `BaseWindow` from which `Control` (the base class for all controls) and `Window` (the final class for top-level windows) are derived.

## Procedural API ##

The procedural API is designed to work with both cdata objects or equivalent Lua types. For a string you can choose to pass a ffi WCHAR buffer, which will be interpreted as UTF-16, or a Lua string, which will be interpreted as UTF-8. For a struct you can choose to pass a struct cdata or a Lua table, same for arrays.

Counting (indexing) starts from 1.

Flags can be passed as either 'FLAG1 | FLAG2 | ...' or as `bit.bor(winapi.FLAG1, winapi.FLAG2, ...)`.

A winapi handle can be owned either by another winapi object or by Lua's garbage collector, to prevent memory leaks. Owning (assigning a destructor) and disowning objects (when windows takes ownership) is taken care of automatically.

Boilerplate like a struct's mask field or a struct/buffer/string size, etc. are hidden from the API. In general, stuff that doesn't relate to actual functionality but it's an artifact of the ABI is considered an unnecessary distraction and so is hidden away.

The API doesn't mimic winapi perfectly. Object constructors like `CreateWindow` take a table with named arguments instead of a list of arguments like in winapi. Argument positions are sometimes reversed to make less-used arguments optional, and so on. Struct fields are renamed to hide away the crazy hungarian notation, etc.

The procedural API is implemented with the aid of a set of utilities dealing with bitmasks, utf-8 conversion, etc. See the [developer documentation](WinapiBinding.md) for more on that.