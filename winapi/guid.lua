--proc/guid: guid types.
setfenv(1, require'winapi')

ffi.cdef[[
typedef struct _GUID {
    unsigned long  Data1;
    unsigned short Data2;
    unsigned short Data3;
    unsigned char  Data4[ 8 ];
} GUID;
typedef GUID IID;
typedef IID *LPIID;
typedef GUID CLSID;
typedef CLSID *LPCLSID;
typedef GUID FMTID;
typedef FMTID *LPFMTID;
typedef IID* REFIID;
]]
