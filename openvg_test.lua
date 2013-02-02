assert(vg, 'load an openvg implementation to run this test')

print("Vendor: ", vg.vgGetString(vg.VG_VENDOR))
print("Renderer: ", vg.vgGetString(vg.VG_RENDERER))
print("Version: ", vg.vgGetString(vg.VG_VERSION))
print("Extensions: ", vg.vgGetString(vg.VG_EXTENSIONS))
