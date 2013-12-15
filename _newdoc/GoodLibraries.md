# What makes a good library

Here's what makes or breaks a library in pattern language form. Patterns (and anti-patterns) can be used for justifying design decisions.

Patterns:
  * distinction - focused problem domain
  * completeness - exhaustive of the problem domain
  * [APIDesign good API]
  * documentation - must be complete and literally one click away (ideally embedded within the editor)
  * packaging - builds without setup on all supported platforms; ideally doesn't need to build at all
  * authors - flexible/responsive authors

Anti-patterns:
  * kitchen sink libraries - lack of focus (by design)
  * lowest common denominator libraries - leaky abstractions
  * offline documentation (burried in the archives) - people need to see the API to decide if the library is what they need in the first place

## Distinction and Completeness
These two go together and are arguably the most important qualities for achieving de-facto status as it leaves little room for competition. Distinction means having a focused problem domain (the single responsibility principle, or one and only one principle), which leads to a functionally cohesive API. Completeness on the other hand means being exhaustive of the problem domain. Firstly, as a requirement to get the job done. Secondly, to avoid bringing in a second library to cover the holes found in the first one.

## Language integration
Use of Lua's native idioms and conventions. See [APIDesign] and the [page](http://lua-users.org/wiki/LuaStyleGuide) on Lua wiki.

## Documentation
  * there's a single project homepage that matches the latest sources
  * usage examples
  * reference docs

## Packaging
Builds without setup on all supported platforms.
  * on Windows, binaries are needed (or again, have a MinGW set up to match the headache free experience of prebuilt binaries)
  * some libraries require to be linked against the same version of Lua and msvcrt to work together

## Relevance
  * works with the latest Lua version and it's compatible with LuaJIT
  * doesn't look abandoned (in lieu of other credentials; so many do)

## Kitchen Sink
The problem with these bundles of generic functionality is that it is hard for another library to justify the dependency on a such library while only using a fraction of it. That wouldn't be a problem for application code, but the lack of a clear problem domain (by design) leads to an even worse situation even there: applications ending up using more than one such library to patch for missing functionality, getting much overlapping functionality in return. Examples: stdlib, Penlight, Underscore. I attacked the problem myself with [glue] but I'm not convinced of the model, even after much effort put into it (and much going on still - maybe I'll see the light someday).

*Solution*: simply split the library by problem domain to see which parts can stand on their own feet.

## Lowest common denominator
*Examples*: generic SQL libraries, cross-platform widget toolkits, cross-platform filesystem libraries, so-called Service Provider Interfaces.

We make these libraries so that we can switch the backends that they drive, should we ever need to. In exchange of that (rarely used) freedom we get a library of limited functionality, that sooner or later we have to bypass with ridiculous hacks to access the functionality it abstracts away. The problem is that the API can't expose any bit of functionality that isn't supported (or can't be efficiently emulated) by every one backend. Each time you add another backend, another layer of functionality must be peeled off the API. Ironically, dumbing down the use of the underlying backends to the lowest common denominator can go against the very criteria for choosing a backend in the first place. Needless to say, backend-specific extensions kill the abstraction, so they are no good either.

*Note*: APIs like POSIX or OpenGL don't count. These APIs are apriori to the implementation, and it's the the implementation that strives to conform to the interface, not the other way around.

*Solution*: resist it.
