//go@ bash build-mingw32.sh
//NPAPI plugin that forwards NPAPI calls to a Lua script
#include <stdint.h>
#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>

/* logging */

// comment the next line if you don't want logging
#define PLUGIN_LOGFILE "x:/work/lua-files/cplayer-plugin/clog.txt"

FILE* logfile;

void say(const char* format, ...) {
#ifdef PLUGIN_LOGFILE
	va_list args;
	if (!logfile)
		logfile = fopen(PLUGIN_LOGFILE, "w");
	va_start(args, format);
	vfprintf(logfile, format, args);
	va_end(args);
	fprintf(logfile, "\n");
	fflush(logfile);
#endif
}

/* Lua */

lua_State *L;
int np_func_ref;

// pcall the function at the top of the Lua stack
int pcall(int nargs, int nresults) {
	if (lua_pcall(L, nargs, nresults, 0)) {
		say("lua_pcall error: %s", lua_tostring(L, -1));
		return 1;
	}
	return 0;
}

// load and run a Lua script that returns the NP forwarding function.
int load_script() {
	if (L) return 0;
	L = luaL_newstate();
	if (!L) {
		say("luaL_newstate error");
		return 1;
	}
	luaL_openlibs(L);
	if (luaL_loadfile(L, "npcplayer.lua")) {
		say("luaL_loadfile error: %s", lua_tostring(L, -1));
		return 1;
	}
	if (pcall(0, 1)) return 1;
	if (!lua_isfunction(L, -1)) {
		say("error: function expected");
		return 1;
	}
	//running the script returned our NP API forwarding function that we keep a reference of in the registry table.
	np_func_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	return 0;
}

// luad the NP forwarding function and its first argument (the name of the NP function to call), into the Lua stack.
int forward(const char* function_name) {
	say(function_name);
	if (load_script()) return 1;
	lua_rawgeti(L, LUA_REGISTRYINDEX, np_func_ref);
	lua_pushstring(L, function_name);
	return 0;
}

/* NPAPI */

int16_t __stdcall NP_GetEntryPoints(void* plugin_funcs) {
	if (forward("NP_GetEntryPoints")) return 1;
	lua_pushlightuserdata(L, plugin_funcs);
	if (pcall(2, 0)) return 1;
	return 0;
}

int16_t __stdcall NP_Initialize(void* browser_funcs) {
	if (forward("NP_Initialize")) return 1;
	lua_pushlightuserdata(L, browser_funcs);
	if (pcall(2, 0)) return 1;
	return 0;
}

int16_t __stdcall NP_Shutdown() {
	if (forward("NP_Shutdown")) return 1;
	if (pcall(1, 0)) return 1;
	lua_close(L);
	L = 0;
	return 0;
}

