--NPAPI binding for windows
local ffi = require'ffi'
--local lanes = require'lanes'.configure()
--local cairo_player = require'cairo_player'

local NP_EMBED = 1 -- Instance was created by an EMBED tag and shares the browser window with other content.
local NP_FULL  = 2 -- Instance was created by a separate file and is the primary content in the window.

ffi.cdef[[
typedef unsigned char NPBool;
typedef int16_t       NPError;
typedef int16_t       NPReason;
typedef char*         NPMIMEType;

/* types and enums that we don't are about: make opaque */

typedef struct        NPStream_ NPStream;
typedef struct        NPSavedData_ NPSavedData;
typedef struct        NPPrint_ NPPrint;
typedef int           NPNVariable;
typedef int           NPFocusDirection;

/* types and enums that we do care about */

typedef struct _NPP {
  void* pdata;      /* plug-in private data */
  void* ndata;      /* netscape private data */
} NPP_t;

typedef NPP_t*  NPP;

typedef struct _NPRect
{
	uint16_t top;
	uint16_t left;
	uint16_t bottom;
	uint16_t right;
} NPRect;

typedef enum {
	NPWindowTypeWindow = 1,
	NPWindowTypeDrawable
} NPWindowType;

typedef struct _NPWindow
{
	void* window;      /* Platform specific window handle */
	int32_t  x;        /* Position of top left corner relative */
	int32_t  y;        /* to a netscape page. */
	uint32_t width;    /* Maximum window size */
	uint32_t height;
	NPRect   clipRect; /* Clipping rectangle in port coordinates */
	NPWindowType type; /* Is this a window or a drawable? */
} NPWindow;

typedef enum {
	NPPVpluginNameString = 1,
	NPPVpluginDescriptionString,
	NPPVpluginWindowBool,
	NPPVpluginTransparentBool,
	NPPVjavaClass,
	NPPVpluginWindowSize,
	NPPVpluginTimerInterval,
	NPPVpluginScriptableInstance = 10,
	NPPVpluginScriptableIID = 11,
	NPPVjavascriptPushCallerBool = 12,
	NPPVpluginKeepLibraryInMemory = 13,
	NPPVpluginNeedsXEmbed         = 14,
	NPPVpluginScriptableNPObject  = 15,
	NPPVformValue = 16,
	NPPVpluginUrlRequestsDisplayedBool = 17,
	NPPVpluginWantsAllNetworkStreams = 18,
	NPPVpluginNativeAccessibleAtkPlugId = 19,
	NPPVpluginCancelSrcStream = 20,
	NPPVsupportsAdvancedKeyHandling = 21,
	NPPVpluginUsesDOMForCursorBool = 22,
	NPPVpluginDrawingModel = 1000,
	NPPVpluginEventModel = 1001,
	NPPVpluginCoreAnimationLayer = 1003
} NPPVariable;

/* plugin-side callbacks */

typedef NPError  (* NPP_NewProcPtr)(NPMIMEType pluginType, NPP instance, uint16_t mode, int16_t argc, char* argn[], char* argv[], NPSavedData* saved);
typedef NPError  (* NPP_DestroyProcPtr)(NPP instance, NPSavedData** save);
typedef NPError  (* NPP_SetWindowProcPtr)(NPP instance, NPWindow* window);
typedef NPError  (* NPP_NewStreamProcPtr)(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16_t* stype);
typedef NPError  (* NPP_DestroyStreamProcPtr)(NPP instance, NPStream* stream, NPReason reason);
typedef int32_t  (* NPP_WriteReadyProcPtr)(NPP instance, NPStream* stream);
typedef int32_t  (* NPP_WriteProcPtr)(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer);
typedef void     (* NPP_StreamAsFileProcPtr)(NPP instance, NPStream* stream, const char* fname);
typedef void     (* NPP_PrintProcPtr)(NPP instance, NPPrint* platformPrint);
typedef int16_t  (* NPP_HandleEventProcPtr)(NPP instance, void* event);
typedef void     (* NPP_URLNotifyProcPtr)(NPP instance, const char* url, NPReason reason, void* notifyData);
typedef NPError  (* NPP_GetValueProcPtr)(NPP instance, NPPVariable variable, void *ret_value);
typedef NPError  (* NPP_SetValueProcPtr)(NPP instance, NPNVariable variable, void *value);
typedef NPBool   (* NPP_GotFocusPtr)(NPP instance, NPFocusDirection direction);
typedef void     (* NPP_LostFocusPtr)(NPP instance);
typedef void     (* NPP_URLRedirectNotifyPtr)(NPP instance, const char* url, int32_t status, void* notifyData);
typedef NPError  (* NPP_ClearSiteDataPtr)(const char* site, uint64_t flags, uint64_t maxAge);
typedef char**   (* NPP_GetSitesWithDataPtr)(void);
typedef void     (* NPP_DidCompositePtr)(NPP instance);

typedef struct _NPPluginFuncs {
	uint16_t size;
	uint16_t version;
	NPP_NewProcPtr newp;
	NPP_DestroyProcPtr destroy;
	NPP_SetWindowProcPtr setwindow;
	NPP_NewStreamProcPtr newstream;
	NPP_DestroyStreamProcPtr destroystream;
	NPP_StreamAsFileProcPtr asfile;
	NPP_WriteReadyProcPtr writeready;
	NPP_WriteProcPtr write;
	NPP_PrintProcPtr print;
	NPP_HandleEventProcPtr event;
	NPP_URLNotifyProcPtr urlnotify;
	void* javaClass;
	NPP_GetValueProcPtr getvalue;
	NPP_SetValueProcPtr setvalue;
	NPP_GotFocusPtr gotfocus;
	NPP_LostFocusPtr lostfocus;
	NPP_URLRedirectNotifyPtr urlredirectnotify;
	NPP_ClearSiteDataPtr clearsitedata;
	NPP_GetSitesWithDataPtr getsiteswithdata;
	NPP_DidCompositePtr didComposite;
} NPPluginFuncs;
]]


--[[
NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16_t* stype) {
	say("NPP_NewStream");
	return 1;
}

NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason) {
	say("NPP_DestroyStream");
	return 1;
}

int32_t NPP_WriteReady(NPP instance, NPStream* stream) {
	say("NPP_WriteReady");
	return 0;
}

int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer) {
	say("NPP_Write");
	return 0;
}

void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname) {
	say("NPP_StreamAsFile");
}

void NPP_Print(NPP instance, NPPrint* platformPrint) {
	say("NPP_Print");
}

int16_t NPP_HandleEvent(NPP instance, void* event) {
	say("NPP_HandleEvent");
	return 1;
}

void NPP_URLNotify(NPP instance, const char* URL, NPReason reason, void* notifyData) {
	say("NPP_URLNotify %s", URL, 0);
}

NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value) {
	say("NPP_GetValue");
	return 1;
}

NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value) {
	say("NPP_SetValue");
	return 1;
}
]]

local logfile = io.open([[x:\work\lua-files\cplayer-plugin\log.txt]], 'w')

local function log(...)
	logfile:write(string.format(...))
	logfile:write('\n')
	logfile:flush()
end

local browser_funcs

local instances = {}

local function new(mime_type, instance, mode, argc, argn, argv, saved)
	log('NPP_New %s, %s', ffi.string(mime_type),
			mode == NP_EMBED and 'NP_EMBED' or mode == NP_FULL and 'NP_FULL' or '?')
	for i=0,argc-1 do
		log('   %-26s %s', ffi.string(argn[i]), ffi.string(argv[i]))
	end

	--instance.pdata = instances
	return 0
end

local function destroy(instance, save)
	log('NPP_Destroy')
	--local inst = instances[tonumber(instance.pdata)]
end

local function setwindow(instance, window)
	log('NPP_SetWindow')
	log('   %-26s %d', 'window.x',               window.x)
	log('   %-26s %d', 'window.y',               window.y)
	log('   %-26s %d', 'window.width',           window.width)
	log('   %-26s %d', 'window.height',          window.height)
	log('   %-26s %d', 'window.clipRect.top',    window.clipRect.top)
	log('   %-26s %d', 'window.clipRect.left',   window.clipRect.left)
	log('   %-26s %d', 'window.clipRect.bottom', window.clipRect.bottom)
	log('   %-26s %d', 'window.clipRect.right',  window.clipRect.right)
	log('   %-26s %s', 'window.type',
		window.type == ffi.C.NPWindowTypeWindow and 'NPWindowTypeWindow' or
		window.type == ffi.C.NPWindowTypeDrawable and 'NPWindowTypeDrawable' or '?')

	--
end

local function newstream(instance, mime_type, stream, seekable, stype)
	return 1
end

local function destroystream(instance, stream, reason)
	return 1
end

local function asfile(instance, stream, fname)
end

local function writeready(instance, stream)
	return 0
end

local function write(instance, stream, offset, len, buffer)
	return 0
end

local function print(instance, platformPrint)
end

local function handleevent(instance, event)
	return 1
end

local function urlnotify(instance, URL, reason, notifyData)
end

local function getvalue(instance, variable, value)
	return 1
end

local function setvalue(instance, variable, value)
	return 1
end

local function safecall(name, f)
	return function(...)
		local ok, err = pcall(f, ...)
		if not ok then
			log('error: %s', err)
			return 0 --NOTE: not always of NPError type
		end
		return err
	end
end

local rpc = {}

function rpc.NP_GetEntryPoints(pfuncs)
	pfuncs = ffi.cast('NPPluginFuncs*', pfuncs)
	pfuncs.newp = safecall(new)
	pfuncs.destroy = safecall(destroy)
	pfuncs.setwindow = safecall(setwindow)
	pfuncs.newstream = safecall(newstream)
	pfuncs.destroystream = safecall(destroystream)
	pfuncs.asfile = safecall(asfile)
	pfuncs.writeready = safecall(writeready)
	pfuncs.write = safecall(write)
	pfuncs.print = safecall(print)
	pfuncs.event = safecall(event)
	pfuncs.urlnotify = safecall(urlnotify)
	pfuncs.getvalue = safecall(getvalue)
	pfuncs.setvalue = safecall(setvalue)
	pfuncs.gotfocus = safecall(gotfocus)
	pfuncs.lostfocus = safecall(lostfocus)
	pfuncs.urlredirectnotify = safecall(urlredirectnotify)
	pfuncs.clearsitedata = safecall(clearsitedata)
	pfuncs.getsiteswithdata = safecall(getsiteswithdata)
	pfuncs.didComposite = safecall(didComposite)
end

function rpc.NP_Initialize(bfuncs)
	browser_funcs = bfuncs
end

function rpc.NP_Shutdown()
end

return function(name, ...)
	assert(rpc[name], 'invalid RPC call')(...)
end

