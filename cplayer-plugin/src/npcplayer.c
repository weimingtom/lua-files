//go@ bash build-mingw32.sh

/* config */

#define PLUGIN_NAME        "Cairo Player"
#define PLUGIN_DESCRIPTION PLUGIN_NAME
#define PLUGIN_VERSION     "1.0.0.0"
#define MIME_DESCRIPTION   "application/x-cairoplayer"
#define PLUGIN_LOGFILE     "x:/work/lua-files/cplayer-plugin/log.txt"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* logging */

FILE* logfile;

void say(const char* format, const char* arg1, const char* arg2) {
	if (!logfile && PLUGIN_LOGFILE)
		logfile = fopen(PLUGIN_LOGFILE, "w");
	fprintf(logfile, format, arg1, arg2);
	fprintf(logfile, "\n");
	fflush(logfile);
}

void sayn(const char* format, int32_t arg1) {
	if (!logfile)
		logfile = fopen("x:/work/lua-files/cplayer-plugin/log.txt", "w");
	fprintf(logfile, format, arg1);
	fprintf(logfile, "\n");
	fflush(logfile);
}

/* running lua scripts */

#include "script.c"

/* basic types */

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

NPError __stdcall NP_Initialize(void* bfuncs) {
	say("NP_Initialize", 0, 0);
	return 0;
}

char* __stdcall NP_GetPluginVersion() {
	say("NP_GetPluginVersion", 0, 0);
	return PLUGIN_VERSION;
}

const char* NP_GetMIMEDescription() {
	say("NP_GetMIMEDescription", 0, 0);
	return MIME_DESCRIPTION;
}

#define NPERR_INVALID_PARAM 9

NPError __stdcall NP_GetValue(void* future, NPPVariable aVariable, void* aValue) {
	say("NP_GetValue", 0, 0);
	switch (aVariable) {
		case NPPVpluginNameString:
			*((char**)aValue) = PLUGIN_NAME;
			break;
		case NPPVpluginDescriptionString:
			*((char**)aValue) = PLUGIN_DESCRIPTION;
			break;
		default:
			return NPERR_INVALID_PARAM;
			break;
	}
	return 0;
}

NPError __stdcall NP_Shutdown() {
	say("NP_Shutdown", 0, 0);
	return 0;
}

NPError NPP_New(NPMIMEType pluginType, NPP instance, uint16_t mode,
						int16_t argc, char* argn[], char* argv[], NPSavedData* saved) {

	say("NPP_New", 0, 0);
	int i;
	for(i = 0; i < argc; i++)
		say("   %-16s %s", argn[i], argv[i]);

	/*
	// set up our our instance data
	InstanceData* instanceData = (InstanceData*)malloc(sizeof(InstanceData));
	if (!instanceData)
	 return NPERR_OUT_OF_MEMORY_ERROR;
	memset(instanceData, 0, sizeof(InstanceData));
	instanceData->npp = instance;
	instance->pdata = instanceData;
	*/
	return 0;
}

NPError NPP_Destroy(NPP instance, NPSavedData** save) {
	say("NPP_Destroy", 0, 0);

	//InstanceData* instanceData = (InstanceData*)(instance->pdata);
	//free(instanceData);
	return 0;
}

NPError NPP_SetWindow(NPP instance, NPWindow* window) {
	say("NPP_SetWindow", 0, 0);
	sayn("   window->x        %d", window->x);
	sayn("   window->y        %d", window->y);
	sayn("   window->w        %d", window->width);
	sayn("   window->h        %d", window->height);
	sayn("   clipRect.top     %d", window->clipRect.top);
	sayn("   clipRect.left    %d", window->clipRect.left);
	sayn("   clipRect.bottom  %d", window->clipRect.bottom);
	sayn("   clipRect.right   %d", window->clipRect.right);
	say ("   type             %s", window->type == NPWindowTypeWindow ? "NPWindowTypeWindow" : "NPWindowTypeDrawable", 0);

	//InstanceData* instanceData = (InstanceData*)(instance->pdata);
	//instanceData->window = *window;
	return 0;
}

NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16_t* stype) {
	say("NPP_NewStream", 0, 0);
	return 1;
}

NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason) {
	say("NPP_DestroyStream", 0, 0);
	return 1;
}

int32_t NPP_WriteReady(NPP instance, NPStream* stream) {
	say("NPP_WriteReady", 0, 0);
	return 0;
}

int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer) {
	say("NPP_Write", 0, 0);
	return 0;
}

void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname) {
	say("NPP_StreamAsFile", 0, 0);
}

void NPP_Print(NPP instance, NPPrint* platformPrint) {
	say("NPP_Print", 0, 0);
}

int16_t NPP_HandleEvent(NPP instance, void* event) {
	say("NPP_HandleEvent", 0, 0);
	return 1;
}

void NPP_URLNotify(NPP instance, const char* URL, NPReason reason, void* notifyData) {
	say("NPP_URLNotify %s", URL, 0);
}

NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value) {
	say("NPP_GetValue", 0, 0);
	return 1;
}

NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value) {
	say("NPP_SetValue", 0, 0);
	return 1;
}


NPError __stdcall NP_GetEntryPoints(NPPluginFuncs* pFuncs) {
	say("NP_GetEntryPoints", 0, 0);
	pFuncs->newp = NPP_New;
	pFuncs->destroy = NPP_Destroy;
	pFuncs->setwindow = NPP_SetWindow;
	pFuncs->newstream = NPP_NewStream;
	pFuncs->destroystream = NPP_DestroyStream;
	pFuncs->asfile = NPP_StreamAsFile;
	pFuncs->writeready = NPP_WriteReady;
	pFuncs->write = NPP_Write;
	pFuncs->print = NPP_Print;
	pFuncs->event = NPP_HandleEvent;
	pFuncs->urlnotify = NPP_URLNotify;
	pFuncs->getvalue = NPP_GetValue;
	pFuncs->setvalue = NPP_SetValue;
}

