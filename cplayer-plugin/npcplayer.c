//go@ bash build-mingw32.sh
//NPAPI plugin that forwards NPAPI calls to a Lua script
#include <stdint.h>
#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>

/* logging */

#define PLUGIN_LOGFILE "x:/work/lua-files/cplayer-plugin/clog.txt"

FILE* logfile;

void say(const char* format, ...) {
	va_list args;
	if (!logfile && PLUGIN_LOGFILE)
		logfile = fopen(PLUGIN_LOGFILE, "w");
	va_start(args, format);
	vfprintf(logfile, format, args);
	va_end(args);
	fprintf(logfile, "\n");
	fflush(logfile);
}

/* Lua */

lua_State *L;
int rpc_func_ref;

// pcall the function at the top of the Lua stack
int pcall(int nargs, int nresults) {
	if (lua_pcall(L, nargs, nresults, 0)) {
		say("lua_pcall error: %s", lua_tostring(L, -1));
		return 1;
	}
	return 0;
}

// load and run a Lua script that returns the RPC function.
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
	//running the script returned our RPC function that we keep a reference of in the registry table.
	rpc_func_ref = luaL_ref(L, LUA_REGISTRYINDEX);
	if (rpc_func_ref == LUA_NOREF || rpc_func_ref == LUA_REFNIL) {
		say("rpc caller returned nothing");
		return 1;
	}
	return 0;
}

// luad the RPC function and its first argument, the RPC function name to call, into the Lua stack.
int rpc(const char* function_name) {
	say(function_name);
	if (load_script()) return 1;
	lua_rawgeti(L, LUA_REGISTRYINDEX, rpc_func_ref);
	lua_pushstring(L, function_name);
	return 0;
}

/* NPAPI */

int16_t __stdcall NP_GetEntryPoints(void* plugin_funcs) {
	if (rpc("NP_GetEntryPoints")) return 1;
	lua_pushlightuserdata(L, plugin_funcs);
	if (pcall(2, 0)) return 1;
	return 0;
}

int16_t __stdcall NP_Initialize(void* browser_funcs) {
	if (rpc("NP_Initialize")) return 1;
	lua_pushlightuserdata(L, browser_funcs);
	if (pcall(2, 0)) return 1;
	return 0;
}

int16_t __stdcall NP_Shutdown() {
	if (rpc("NP_Shutdown")) return 1;
	if (pcall(1, 0)) return 1;
	lua_close(L);
	L = 0;
	return 0;
}

