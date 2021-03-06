--NPAPI binding for windows
local ffi = require'ffi'

package.path = 'x:/work/lua-files/?.lua'
package.cpath = 'x:/work/lua-files/?.dll;x:/work/lua-files/bin/?.dll'
--require'strict'
local lanes = require'lanes'.configure()

local NP_EMBED = 1 -- Instance was created by an EMBED tag and shares the browser window with other content.
local NP_FULL  = 2 -- Instance was created by a separate file and is the primary content in the window.

ffi.cdef[[
/* basic types */

typedef unsigned char NPBool;
typedef int16_t       NPError;
typedef int16_t       NPReason;
typedef char*         NPMIMEType;

/* NPP ******************************************************************************************* */

/* NPP types and enums that we don't are about: make opaque */

typedef struct        NPStream_ NPStream;
typedef struct        NPSavedData_ NPSavedData;
typedef struct        NPPrint_ NPPrint;
typedef int           NPNVariable;
typedef int           NPFocusDirection;

/* NPP types and enums */

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

/* NPP (plugin side) callbacks */

typedef NPError  (* NPP_NewProcPtr)(NPMIMEType pluginType, NPP instance, uint16_t mode, int16_t argc, char* argn[], char* argv[], NPSavedData* saved);
typedef NPError  (* NPP_DestroyProcPtr)(NPP instance, NPSavedData** save);
typedef NPError  (* NPP_SetWindowProcPtr)(NPP instance, NPWindow* window);
typedef NPError  (* NPP_NewStreamProcPtr)(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16_t* stype);
typedef NPError  (* NPP_DestroyStreamProcPtr)(NPP instance, NPStream* stream, NPReason reason);
typedef void     (* NPP_StreamAsFileProcPtr)(NPP instance, NPStream *stream, const char *fname);
typedef int32_t  (* NPP_WriteReadyProcPtr)(NPP instance, NPStream* stream);
typedef int32_t  (* NPP_WriteProcPtr)(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer);
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
} NPPluginFuncs;

/* NPN ******************************************************************************************* */

/* NPN types and enums */

typedef struct _NPByteRange
{
  int32_t  offset; /* negative offset means from the end */
  uint32_t length;
  struct _NPByteRange* next;
} NPByteRange;

typedef char NPUTF8;
typedef struct _NPString {
    const NPUTF8 *UTF8Characters;
    uint32_t UTF8Length;
} NPString;

typedef void* NPRegion; //HRGN in windows
typedef void *NPIdentifier;

typedef struct NPObject NPObject;
typedef struct NPClass NPClass;

typedef enum {
    NPVariantType_Void,
    NPVariantType_Null,
    NPVariantType_Bool,
    NPVariantType_Int32,
    NPVariantType_Double,
    NPVariantType_String,
    NPVariantType_Object
} NPVariantType;

typedef struct _NPVariant {
    NPVariantType type;
    union {
        bool boolValue;
        int32_t intValue;
        double doubleValue;
        NPString stringValue;
        NPObject *objectValue;
    } value;
} NPVariant;

typedef enum {
  NPNURLVCookie = 501,
  NPNURLVProxy
} NPNURLVariable;

typedef void *NPMenu;

typedef enum {
  NPCoordinateSpacePlugin = 1,
  NPCoordinateSpaceWindow,
  NPCoordinateSpaceFlippedWindow,
  NPCoordinateSpaceScreen,
  NPCoordinateSpaceFlippedScreen
} NPCoordinateSpace;

/* NPN (plugin side) callbacks */

typedef NPError      (*NPN_GetValueProcPtr)(NPP instance, NPNVariable variable, void *ret_value);
typedef NPError      (*NPN_SetValueProcPtr)(NPP instance, NPPVariable variable, void *value);
typedef NPError      (*NPN_GetURLNotifyProcPtr)(NPP instance, const char* url, const char* window, void* notifyData);
typedef NPError      (*NPN_PostURLNotifyProcPtr)(NPP instance, const char* url, const char* window, uint32_t len, const char* buf, NPBool file, void* notifyData);
typedef NPError      (*NPN_GetURLProcPtr)(NPP instance, const char* url, const char* window);
typedef NPError      (*NPN_PostURLProcPtr)(NPP instance, const char* url, const char* window, uint32_t len, const char* buf, NPBool file);
typedef NPError      (*NPN_RequestReadProcPtr)(NPStream* stream, NPByteRange* rangeList);
typedef NPError      (*NPN_NewStreamProcPtr)(NPP instance, NPMIMEType type, const char* window, NPStream** stream);
typedef int32_t      (*NPN_WriteProcPtr)(NPP instance, NPStream* stream, int32_t len, void* buffer);
typedef NPError      (*NPN_DestroyStreamProcPtr)(NPP instance, NPStream* stream, NPReason reason);
typedef void         (*NPN_StatusProcPtr)(NPP instance, const char* message);
/* Browser manages the lifetime of the buffer returned by NPN_UserAgent, don't
   depend on it sticking around and don't free it. */
typedef const char*  (*NPN_UserAgentProcPtr)(NPP instance);
typedef void*        (*NPN_MemAllocProcPtr)(uint32_t size);
typedef void         (*NPN_MemFreeProcPtr)(void* ptr);
typedef uint32_t     (*NPN_MemFlushProcPtr)(uint32_t size);
typedef void         (*NPN_ReloadPluginsProcPtr)(NPBool reloadPages);
typedef void*        (*NPN_GetJavaEnvProcPtr)(void);
typedef void*        (*NPN_GetJavaPeerProcPtr)(NPP instance);
typedef void         (*NPN_InvalidateRectProcPtr)(NPP instance, NPRect *rect);
typedef void         (*NPN_InvalidateRegionProcPtr)(NPP instance, NPRegion region);
typedef void         (*NPN_ForceRedrawProcPtr)(NPP instance);
typedef NPIdentifier (*NPN_GetStringIdentifierProcPtr)(const NPUTF8* name);
typedef void         (*NPN_GetStringIdentifiersProcPtr)(const NPUTF8** names, int32_t nameCount, NPIdentifier* identifiers);
typedef NPIdentifier (*NPN_GetIntIdentifierProcPtr)(int32_t intid);
typedef bool         (*NPN_IdentifierIsStringProcPtr)(NPIdentifier identifier);
typedef NPUTF8*      (*NPN_UTF8FromIdentifierProcPtr)(NPIdentifier identifier);
typedef int32_t      (*NPN_IntFromIdentifierProcPtr)(NPIdentifier identifier);
typedef NPObject*    (*NPN_CreateObjectProcPtr)(NPP npp, NPClass *aClass);
typedef NPObject*    (*NPN_RetainObjectProcPtr)(NPObject *obj);
typedef void         (*NPN_ReleaseObjectProcPtr)(NPObject *obj);
typedef bool         (*NPN_InvokeProcPtr)(NPP npp, NPObject* obj, NPIdentifier methodName, const NPVariant *args, uint32_t argCount, NPVariant *result);
typedef bool         (*NPN_InvokeDefaultProcPtr)(NPP npp, NPObject* obj, const NPVariant *args, uint32_t argCount, NPVariant *result);
typedef bool         (*NPN_EvaluateProcPtr)(NPP npp, NPObject *obj, NPString *script, NPVariant *result);
typedef bool         (*NPN_GetPropertyProcPtr)(NPP npp, NPObject *obj, NPIdentifier propertyName, NPVariant *result);
typedef bool         (*NPN_SetPropertyProcPtr)(NPP npp, NPObject *obj, NPIdentifier propertyName, const NPVariant *value);
typedef bool         (*NPN_RemovePropertyProcPtr)(NPP npp, NPObject *obj, NPIdentifier propertyName);
typedef bool         (*NPN_HasPropertyProcPtr)(NPP npp, NPObject *obj, NPIdentifier propertyName);
typedef bool         (*NPN_HasMethodProcPtr)(NPP npp, NPObject *obj, NPIdentifier propertyName);
typedef void         (*NPN_ReleaseVariantValueProcPtr)(NPVariant *variant);
typedef void         (*NPN_SetExceptionProcPtr)(NPObject *obj, const NPUTF8 *message);
typedef void         (*NPN_PushPopupsEnabledStateProcPtr)(NPP npp, NPBool enabled);
typedef void         (*NPN_PopPopupsEnabledStateProcPtr)(NPP npp);
typedef bool         (*NPN_EnumerateProcPtr)(NPP npp, NPObject *obj, NPIdentifier **identifier, uint32_t *count);
typedef void         (*NPN_PluginThreadAsyncCallProcPtr)(NPP instance, void (*func)(void *), void *userData);
typedef bool         (*NPN_ConstructProcPtr)(NPP npp, NPObject* obj, const NPVariant *args, uint32_t argCount, NPVariant *result);
typedef NPError      (*NPN_GetValueForURLPtr)(NPP npp, NPNURLVariable variable, const char *url, char **value, uint32_t *len);
typedef NPError      (*NPN_SetValueForURLPtr)(NPP npp, NPNURLVariable variable, const char *url, const char *value, uint32_t len);
typedef NPError      (*NPN_GetAuthenticationInfoPtr)(NPP npp, const char *protocol, const char *host, int32_t port, const char *scheme, const char *realm, char **username, uint32_t *ulen, char **password, uint32_t *plen);
typedef uint32_t     (*NPN_ScheduleTimerPtr)(NPP instance, uint32_t interval, NPBool repeat, void (*timerFunc)(NPP npp, uint32_t timerID));
typedef void         (*NPN_UnscheduleTimerPtr)(NPP instance, uint32_t timerID);
typedef NPError      (*NPN_PopUpContextMenuPtr)(NPP instance, NPMenu* menu);
typedef NPBool       (*NPN_ConvertPointPtr)(NPP instance, double sourceX, double sourceY, NPCoordinateSpace sourceSpace, double *destX, double *destY, NPCoordinateSpace destSpace);
typedef NPBool       (*NPN_HandleEventPtr)(NPP instance, void *event, NPBool handled);
typedef NPBool       (*NPN_UnfocusInstancePtr)(NPP instance, NPFocusDirection direction);
typedef void         (*NPN_URLRedirectResponsePtr)(NPP instance, void* notifyData, NPBool allow);

typedef struct _NPNetscapeFuncs {
  uint16_t size;
  uint16_t version;
  NPN_GetURLProcPtr geturl;
  NPN_PostURLProcPtr posturl;
  NPN_RequestReadProcPtr requestread;
  NPN_NewStreamProcPtr newstream;
  NPN_WriteProcPtr write;
  NPN_DestroyStreamProcPtr destroystream;
  NPN_StatusProcPtr status;
  NPN_UserAgentProcPtr uagent;
  NPN_MemAllocProcPtr memalloc;
  NPN_MemFreeProcPtr memfree;
  NPN_MemFlushProcPtr memflush;
  NPN_ReloadPluginsProcPtr reloadplugins;
  NPN_GetJavaEnvProcPtr getJavaEnv;
  NPN_GetJavaPeerProcPtr getJavaPeer;
  NPN_GetURLNotifyProcPtr geturlnotify;
  NPN_PostURLNotifyProcPtr posturlnotify;
  NPN_GetValueProcPtr getvalue;
  NPN_SetValueProcPtr setvalue;
  NPN_InvalidateRectProcPtr invalidaterect;
  NPN_InvalidateRegionProcPtr invalidateregion;
  NPN_ForceRedrawProcPtr forceredraw;
  NPN_GetStringIdentifierProcPtr getstringidentifier;
  NPN_GetStringIdentifiersProcPtr getstringidentifiers;
  NPN_GetIntIdentifierProcPtr getintidentifier;
  NPN_IdentifierIsStringProcPtr identifierisstring;
  NPN_UTF8FromIdentifierProcPtr utf8fromidentifier;
  NPN_IntFromIdentifierProcPtr intfromidentifier;
  NPN_CreateObjectProcPtr createobject;
  NPN_RetainObjectProcPtr retainobject;
  NPN_ReleaseObjectProcPtr releaseobject;
  NPN_InvokeProcPtr invoke;
  NPN_InvokeDefaultProcPtr invokeDefault;
  NPN_EvaluateProcPtr evaluate;
  NPN_GetPropertyProcPtr getproperty;
  NPN_SetPropertyProcPtr setproperty;
  NPN_RemovePropertyProcPtr removeproperty;
  NPN_HasPropertyProcPtr hasproperty;
  NPN_HasMethodProcPtr hasmethod;
  NPN_ReleaseVariantValueProcPtr releasevariantvalue;
  NPN_SetExceptionProcPtr setexception;
  NPN_PushPopupsEnabledStateProcPtr pushpopupsenabledstate;
  NPN_PopPopupsEnabledStateProcPtr poppopupsenabledstate;
  NPN_EnumerateProcPtr enumerate;
  NPN_PluginThreadAsyncCallProcPtr pluginthreadasynccall;
  NPN_ConstructProcPtr construct;
  NPN_GetValueForURLPtr getvalueforurl;
  NPN_SetValueForURLPtr setvalueforurl;
  NPN_GetAuthenticationInfoPtr getauthenticationinfo;
  NPN_ScheduleTimerPtr scheduletimer;
  NPN_UnscheduleTimerPtr unscheduletimer;
  NPN_PopUpContextMenuPtr popupcontextmenu;
  NPN_ConvertPointPtr convertpoint;
  NPN_HandleEventPtr handleevent;
  NPN_UnfocusInstancePtr unfocusinstance;
  NPN_URLRedirectResponsePtr urlredirectresponse;
} NPNetscapeFuncs;

]]

--helpers

local function ptonumber(ptr) --pointer to number so we can pass it to linda
	return ptr ~= nil and tonumber(ffi.cast('ptrdiff_t', ptr)) or nil
end

--logging

local function log_function(filename)
	if type(filename) == 'string' then
		local f
		return function(...)
			f = f or io.open(filename, 'w')
			f:write(string.format(...))
			f:write('\n')
			f:flush()
		end
	else
		return function(...)
			return filename(string.format(...))
		end
	end
end

local function log() end --stub, overriden later

--NP API forwarder

local np = {} --{'NP_*' = np_func}

function forward(name, ...)
	log(name)
	assert(np[name], 'invalid NP call')(...)
end

--NP API: module init/shutdown - getting the browser object

local browser --pointer to a NPNetscapeFuncs struct for calling the browser API

function np.NP_Initialize(bfuncs)
	assert(bfuncs ~= nil)
	browser = ffi.cast('NPNetscapeFuncs*', bfuncs)
	log('   %-26s %d', 'browser.size',    browser.size)
	log('   %-26s %d', 'browser.version', browser.version)
end

function np.NP_Shutdown()
	browser = nil
end

--NP API: plugin callback table setup

local npp = {} --{'NPP_*' = npp_func}

--NPP_* function wrapper that logs the call, pcalls the function, logs the result,
--and returns the appropriate return value depending on success or failure.
local function npp_safewrap(name, npp_error_ret, npp_ok_ret)
	local npp_func = npp[name]
	if npp_func then
		return function(...)
			log(name)
			local ok, ret = pcall(npp_func, ...)
			if not ok then --crashed: log the error and return the error return value.
				log('   error: %s', ret)
				ret = npp_error_ret
			elseif ret == nil then --nothing was returned: assume the default value for success.
				ret = npp_ok_ret
			end
			log('   ok: %s', tostring(ret))
			return ret
		end
	else
		return function()
			log('%-29s %s', name, '(not implemented)')
			log('   error: %s', npp_error_ret)
			return npp_error_ret
		end
	end
end

function np.NP_GetEntryPoints(pfuncs)
	assert(pfuncs ~= nil)
	pfuncs = ffi.cast('NPPluginFuncs*', pfuncs)
	assert(pfuncs.size >= ffi.sizeof('NPPluginFuncs'),
		'pfunc.size is '..tostring(pfuncs.size)..' should be '..ffi.sizeof('NPPluginFuncs'))
	pfuncs.newp              = npp_safewrap('NPP_New', 1, 0)
	pfuncs.destroy           = npp_safewrap('NPP_Destroy', 1, 0)
	pfuncs.setwindow         = npp_safewrap('NPP_SetWindow', 1, 0)
	pfuncs.newstream         = npp_safewrap('NPP_NewStream', 1, 0)
	pfuncs.destroystream     = npp_safewrap('NPP_DestroyStream', 1, 0)
	pfuncs.asfile            = npp_safewrap('NPP_StreamAsFile')
	pfuncs.writeready        = npp_safewrap('NPP_WriteReady', 0, 0)
	pfuncs.write             = npp_safewrap('NPP_Write', 0, 0)
	pfuncs.print             = npp_safewrap('NPP_Print')
	pfuncs.event             = npp_safewrap('NPP_HandleEvent', 0, 1)
	pfuncs.urlnotify         = npp_safewrap('NPP_URLNotify')
	pfuncs.getvalue          = npp_safewrap('NPP_GetValue', 1, 0)
	pfuncs.setvalue          = npp_safewrap('NPP_SetValue', 1, 0)
	pfuncs.gotfocus          = npp_safewrap('NPP_GotFocus', 0, 1)
	pfuncs.lostfocus         = npp_safewrap('NPP_LostFocus')
	pfuncs.urlredirectnotify = npp_safewrap('NPP_URLRedirectNotify')
	pfuncs.clearsitedata     = npp_safewrap('NPP_ClearSiteData', 1, 0)
	pfuncs.getsiteswithdata  = npp_safewrap('NPP_GetSitesWithData', nil, nil)
end

--instance tracking based on autogenerated ids

local instance_class --forward decl. to the hi-level plugin class bellow

local last_instance_id = 0 --autoincremented id for instances

local function gen_instance_id()
	last_instance_id = last_instance_id + 1
	if last_instance_id >= 2^31 then --some people never close their browser
		last_instance_id = 0
	end
	return last_instance_id
end

local instances = {} --{instance_id = instance_t}

local function new_instance(instance, args, browser)
	local id = gen_instance_id()
	instances[id] = instance_class:new(id, instance, args, browser)
	instance.pdata = ffi.cast('void*', id)
end

local function instance_id(instance)
	return ptonumber(instance.pdata)
end

local function find_instance(instance)
	return assert(instances[instance_id(instance)], 'invalid instance')
end

local function free_instance(instance)
	local id = instance_id(instance)
	find_instance(instance):free()
	instances[id] = nil
	instance.pdata = nil
end

--NPP API: instance creation/destruction

function npp.NPP_New(mime_type, instance, mode, argc, argn, argv, saved)
	log('   %-26s %s', 'mime_type', ffi.string(mime_type))
	log('   %-26s %s', 'mode', mode == NP_EMBED and 'NP_EMBED' or mode == NP_FULL and 'NP_FULL' or '?')
	local args = {}
	for i=0,argc-1 do
		local k, v = ffi.string(argn[i]), ffi.string(argv[i])
		args[k] = v
		log('   %-26s %s', k, v)
	end
	new_instance(instance, args, browser)
end

function npp.NPP_Destroy(instance, save)
	free_instance(instance)
end

--NPP API: instance events

local window_types = {
	[ffi.C.NPWindowTypeWindow] = 'window',
	[ffi.C.NPWindowTypeDrawable] = 'drawable',
}
function npp.NPP_SetWindow(instance, window)
	local window_type = window_types[tonumber(window.type)]
	log('   %-26s %s', 'window.window',          tostring(window.window))
	log('   %-26s %d', 'window.x',               window.x)
	log('   %-26s %d', 'window.y',               window.y)
	log('   %-26s %d', 'window.width',           window.width)
	log('   %-26s %d', 'window.height',          window.height)
	log('   %-26s %d', 'window.clipRect.top',    window.clipRect.top)
	log('   %-26s %d', 'window.clipRect.left',   window.clipRect.left)
	log('   %-26s %d', 'window.clipRect.bottom', window.clipRect.bottom)
	log('   %-26s %d', 'window.clipRect.right',  window.clipRect.right)
	log('   %-26s %s', 'window.type',            window_type or '?')
	find_instance(instance):set_window(window_type, window.window,
													window.x, window.y, window.width, window.height,
													window.clipRect.left, window.clipRect.top,
													window.clipRect.right - window.clipRect.left,
													window.clipRect.bottom - window.clipRect.top)
end

--[[
local varnames = {
	[ffi.C.NPPVpluginNameString] = 'NPPVpluginNameString',
	[ffi.C.NPPVpluginDescriptionString] = 'NPPVpluginDescriptionString',
	[ffi.C.NPPVpluginWindowBool] = 'NPPVpluginWindowBool',
	[ffi.C.NPPVpluginTransparentBool] = 'NPPVpluginTransparentBool',
	[ffi.C.NPPVjavaClass] = 'NPPVjavaClass',
	[ffi.C.NPPVpluginWindowSize] = 'NPPVpluginWindowSize',
	[ffi.C.NPPVpluginTimerInterval] = 'NPPVpluginTimerInterval',
	[ffi.C.NPPVpluginScriptableInstance] = 'NPPVpluginScriptableInstance',
	[ffi.C.NPPVpluginScriptableIID] = 'NPPVpluginScriptableIID',
	[ffi.C.NPPVjavascriptPushCallerBool] = 'NPPVjavascriptPushCallerBool',
	[ffi.C.NPPVpluginKeepLibraryInMemory] = 'NPPVpluginKeepLibraryInMemory',
	[ffi.C.NPPVpluginNeedsXEmbed] = 'NPPVpluginNeedsXEmbed',
	[ffi.C.NPPVpluginScriptableNPObject] = 'NPPVpluginScriptableNPObject',
	[ffi.C.NPPVformValue] = 'NPPVformValue',
	[ffi.C.NPPVpluginUrlRequestsDisplayedBool] = 'NPPVpluginUrlRequestsDisplayedBool',
	[ffi.C.NPPVpluginWantsAllNetworkStreams] = 'NPPVpluginWantsAllNetworkStreams',
	[ffi.C.NPPVpluginNativeAccessibleAtkPlugId] = 'NPPVpluginNativeAccessibleAtkPlugId',
	[ffi.C.NPPVpluginCancelSrcStream] = 'NPPVpluginCancelSrcStream',
	[ffi.C.NPPVsupportsAdvancedKeyHandling] = 'NPPVsupportsAdvancedKeyHandling',
	[ffi.C.NPPVpluginUsesDOMForCursorBool] = 'NPPVpluginUsesDOMForCursorBool',
	[ffi.C.NPPVpluginDrawingModel] = 'NPPVpluginDrawingModel',
	[ffi.C.NPPVpluginEventModel] = 'NPPVpluginEventModel',
	[ffi.C.NPPVpluginCoreAnimationLayer] = 'NPPVpluginCoreAnimationLayer',
}

function npp.NPP_GetValue(instance, var, buf)
	log('   %-26s', varnames[tonumber(var)] or tostring(var))
	error'NYI'
end
]]

--hi-level plugin API: instance objects

local inst = {} --instance class

local winapi = require'winapi'
require'winapi.window'
require'winapi.windowmessages'

function inst:new(id, instance, args, browser) --not global but fwd. decl.
	log('   %-26s %d', 'inst:new()', id)
	self = setmetatable({id = id, instance = instance, args = args, browser = browser}, {__index = self})
	self.linda = lanes.linda()
	self.thread = self.create_thread(self.linda, self.id)
	log('   %-26s -> %s', 'inst.create_thread()', tostring(self.thread))
	return self
end

function inst:free()
	log('   %-26s %d', 'inst:free()', self.id)
	self:send('free')
	local _, err = self.thread:join(1)
	if self.thread.status ~= 'done' then
		self.thread:cancel(0, true)
		assert(self.thread.status == 'killed')
		log('   killed')
	end
end

function inst:set_window(wintype, hwnd, x, y, w, h, cx, cy, cw, ch)
	self.hwnd = hwnd
	hwnd = ptonumber(hwnd)
	log('   %-26s %s, %d, %d, %d, %d, %d', 'inst:set_window()', wintype, hwnd, x, y, w, h)
	assert(not hwnd or wintype == 'window') --we only support native windows
	self:send('set_window', hwnd, x, y, w, h, cx, cy, cw, ch)
	--self.browser.geturlnotify(self.instance, 'https://lua-files.googlecode.com/hg/bin/cairo.dll', nil, nil)
end

function inst:send(msg, ...)
	self.linda:send('cmd', {msg, ...})
	if self.hwnd then
		winapi.PostMessage(self.hwnd, winapi.WM_NULL) --unstick the main loop
	end
end

function inst:ping()
	if self.thread.status ~= 'running' then
		self:free()
	end
end

--the thread communicates through the linda arg only: don't add more upvalues.
inst.create_thread = lanes.gen('*', function(linda, id)
	local ffi = require'ffi'
	local winapi = require'winapi'
	require'winapi.messageloop'

	local log = log_function(print)
	--local log = log_function(string.format('x:/work/lua-files/cplayer-plugin/log-%d.txt', id))
	log('%-29s %s', 'thread started', id)

	local player, last_hwnd

	local next_message = coroutine.wrap(function()
		winapi.MessageLoop(function(msg)
			coroutine.yield(true)
		end)
	end)

	local function close_player()
		if not player then return end
		log('   close_player()')
		player = nil
	end

	while true do
		local timeout = player and 0 or 1
		local _, cmd = linda:receive(timeout, 'cmd')

		if cmd then
			log('%-29s %s', 'linda:receive("cmd")', table.concat(cmd, ', '))

			if cmd[1] == 'free' then
				close_player()
				return
			elseif cmd[1] == 'set_window' then
				local hwnd, x, y, w, h, cx, cy, cw, ch = unpack(cmd, 2)
				hwnd = ffi.cast('void*', hwnd)

				if hwnd == nil or hwnd ~= last_hwnd then
					close_player()
					if hwnd then
						player = require'cplayer_demo'
						player.main = player:window{on_render = player.on_render, parent = hwnd}
					end
				else
					--resize
				end

				last_hwnd = hwnd
			end
		end

		if player then
			next_message()
		end
	end
end)

--main

instance_class = inst

if not ... then
	--simmulate a browser session
	log = log_function(print)
	local winapi = require'winapi'
	require'winapi.windowclass'
	require'winapi.messageloop'

	local function start_inst(id)
		local window = winapi.Window{w = 800, h = 500, autoquit = true}
		local inst = inst:new(1, nil, {}, nil)
		inst:set_window('window', window.hwnd, 0, 0, 100, 100, 0, 0, 0, 0)
		return inst
	end
	local inst1 = start_inst(1)
	local inst2 = start_inst(2)
	winapi.MessageLoop(function()
		inst1:ping()
		inst2:ping()
	end)
	inst1:free()
	inst2:free()
else
	--comment this if you don't want logging
	log = log_function'x:/work/lua-files/cplayer-plugin/log.txt'
end

--the module has a single-entrypoint API which is the NP forwarder function
return forward

