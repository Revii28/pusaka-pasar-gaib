"""Blender-side normalizer (run via `blender --background --python this -- NAME INPUT TEXDIR OUTDIR`).

Called by scripts/normalize_sketchfab.py once per setan. Imports a Sketchfab
model (.fbx/.glb/.gltf/.blend), best-effort reconnects/rebuilds PBR textures
from the download folder, decimates >15k tri, downscales >2048 textures,
normalizes scale, packs, and re-exports a self-contained FBX + 512 preview to
OUTDIR (a temp dir; the orchestrator moves results into the repo because
Blender cannot write into the Documents tree on this machine).
"""
import bpy, os, sys, json, math, mathutils

argv = sys.argv[sys.argv.index("--") + 1:]
NAME, INPUT, TEXDIR, OUTDIR = argv[0], argv[1], argv[2], argv[3]
os.makedirs(OUTDIR, exist_ok=True)
res = {"name": NAME, "input": os.path.basename(INPUT)}


def emit():
    print("RESULT=" + json.dumps(res), flush=True)
    print("NORMALIZE_DONE", flush=True)
    sys.exit(0)


for mod in ("io_scene_fbx", "io_scene_gltf2"):
    try:
        bpy.ops.preferences.addon_enable(module=mod)
    except Exception:
        pass

ext = os.path.splitext(INPUT)[1].lower()
res["ext"] = ext
if ext != ".blend":
    bpy.ops.wm.read_factory_settings(use_empty=True)

try:
    if ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=INPUT)
    elif ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=INPUT)
    elif ext == ".blend":
        bpy.ops.wm.open_mainfile(filepath=INPUT)
    else:
        res["error"] = f"unsupported ext {ext}"
        emit()
except Exception as e:
    res["error"] = f"import failed: {e!r}"
    emit()

mesh_objs = [o for o in bpy.data.objects if o.type == 'MESH']
res["mesh_objects"] = len(mesh_objs)
res["materials"] = len(bpy.data.materials)

TEX_EXTS = (".png", ".jpg", ".jpeg", ".tga", ".bmp", ".tif", ".tiff")


def list_textures(texdir):
    out = []
    if os.path.isdir(texdir):
        for f in os.listdir(texdir):
            if f.lower().endswith(TEX_EXTS):
                full = os.path.join(texdir, f)
                try:
                    out.append((f, full, os.path.getsize(full)))
                except Exception:
                    pass
    return out


def categorize(texs):
    cats = {"normal": [], "rough": [], "metal": [], "ao": [], "color": [], "other": []}
    for (f, full, sz) in texs:
        lf = f.lower()
        if "normal" in lf or "_norm" in lf or "_nrm" in lf or "_n." in lf:
            cats["normal"].append(full)
        elif "rough" in lf:
            cats["rough"].append(full)
        elif "metal" in lf:
            cats["metal"].append(full)
        elif "_ao" in lf or "occlusion" in lf or "ambient" in lf:
            cats["ao"].append(full)
        elif any(k in lf for k in ("albedo", "basecolor", "base_color", "diffuse", "_color", "_col", "baked")):
            cats["color"].append(full)
        else:
            cats["other"].append((full, sz))
    if not cats["color"] and cats["other"]:
        cats["other"].sort(key=lambda x: -x[1])
        cats["color"] = [cats["other"][0][0]]
    cats["other"] = [o[0] for o in cats["other"]]
    return cats


_img_cache = {}


def load_img(path, noncolor=False):
    key = (path, noncolor)
    if key in _img_cache:
        return _img_cache[key]
    try:
        img = bpy.data.images.load(path, check_existing=True)
        if noncolor:
            try:
                img.colorspace_settings.name = 'Non-Color'
            except Exception:
                pass
        _img_cache[key] = img
        return img
    except Exception:
        return None


def best(cands, matname):
    if not cands:
        return None
    mn = (matname or "").lower()
    for c in cands:
        if mn and mn in os.path.basename(c).lower():
            return c
    return cands[0]


def input_has_image(inp):
    for l in inp.links:
        fn = l.from_node
        if fn.type == 'TEX_IMAGE' and fn.image and fn.image.size[0] > 0:
            return True
        if fn.type == 'NORMAL_MAP':
            for l2 in fn.inputs['Color'].links:
                src = l2.from_node
                if src.type == 'TEX_IMAGE' and src.image and src.image.size[0] > 0:
                    return True
    return False


def ensure_textured(mat, cats):
    if not mat.use_nodes:
        mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    if not bsdf:
        for n in nt.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                bsdf = n
                break
    if not bsdf:
        return 0
    added = 0
    xy = [-700, 300]

    def mk(path, noncolor):
        img = load_img(path, noncolor)
        if not img:
            return None
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = img
        xy[1] -= 280
        t.location = (xy[0], xy[1])
        return t

    if cats["color"] and not input_has_image(bsdf.inputs["Base Color"]):
        t = mk(best(cats["color"], mat.name), False)
        if t:
            nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
            added += 1
    if cats["rough"] and "Roughness" in bsdf.inputs and not input_has_image(bsdf.inputs["Roughness"]):
        t = mk(best(cats["rough"], mat.name), True)
        if t:
            nt.links.new(t.outputs["Color"], bsdf.inputs["Roughness"])
            added += 1
    if cats["metal"] and "Metallic" in bsdf.inputs and not input_has_image(bsdf.inputs["Metallic"]):
        t = mk(best(cats["metal"], mat.name), True)
        if t:
            nt.links.new(t.outputs["Color"], bsdf.inputs["Metallic"])
            added += 1
    if cats["normal"] and "Normal" in bsdf.inputs and not input_has_image(bsdf.inputs["Normal"]):
        t = mk(best(cats["normal"], mat.name), True)
        if t:
            nm = nt.nodes.new("ShaderNodeNormalMap")
            nm.location = (xy[0] + 250, xy[1])
            nt.links.new(t.outputs["Color"], nm.inputs["Color"])
            nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
            added += 1
    return added


cats = categorize(list_textures(TEXDIR))
res["tex_cats"] = {k: len(v) for k, v in cats.items()}

auto_loaded = sum(1 for i in bpy.data.images if i.size[0] > 0)
if NAME == "Banaspati" or (auto_loaded == 0 and not any(cats.values()) and ext == ".blend"):
    mat = bpy.data.materials.new("BanaspatiFire")
    mat.use_nodes = True
    b = mat.node_tree.nodes.get("Principled BSDF")
    if b:
        b.inputs["Base Color"].default_value = (1.0, 0.4, 0.02, 1.0)
        if "Emission Color" in b.inputs:
            b.inputs["Emission Color"].default_value = (1.0, 0.4, 0.02, 1.0)
            b.inputs["Emission Strength"].default_value = 5.0
    for o in mesh_objs:
        o.data.materials.clear()
        o.data.materials.append(mat)
    res["banaspati_fallback"] = True
else:
    fixed = 0
    for mat in bpy.data.materials:
        if mat.use_nodes or mat.node_tree:
            try:
                fixed += ensure_textured(mat, cats)
            except Exception:
                pass
    res["texture_nodes_added"] = fixed

res["images_with_data"] = sum(1 for i in bpy.data.images if i.size[0] > 0)

downscaled = 0
for img in bpy.data.images:
    try:
        if img.size[0] > 2048 or img.size[1] > 2048:
            img.scale(min(img.size[0], 2048), min(img.size[1], 2048))
            downscaled += 1
    except Exception:
        pass
res["downscaled"] = downscaled


def total_tris():
    t = 0
    for o in bpy.data.objects:
        if o.type == 'MESH':
            try:
                o.data.calc_loop_triangles()
                t += len(o.data.loop_triangles)
            except Exception:
                pass
    return t


tris0 = total_tris()
res["tri_before"] = tris0
if tris0 > 15000:
    ratio = max(0.02, min(0.95, 10000.0 / tris0))
    for o in mesh_objs:
        try:
            bpy.context.view_layer.objects.active = o
            m = o.modifiers.new("Dec", 'DECIMATE')
            m.ratio = ratio
            bpy.ops.object.modifier_apply(modifier=m.name)
        except Exception:
            pass
res["tri_after"] = total_tris()


def combined_bbox():
    mins = [1e9, 1e9, 1e9]
    maxs = [-1e9, -1e9, -1e9]
    found = False
    for o in bpy.data.objects:
        if o.type == 'MESH':
            for c in o.bound_box:
                w = o.matrix_world @ mathutils.Vector(c)
                for i in range(3):
                    mins[i] = min(mins[i], w[i])
                    maxs[i] = max(maxs[i], w[i])
                found = True
    if not found:
        return None, None
    return mathutils.Vector(mins), mathutils.Vector(maxs)


mn, mx = combined_bbox()
if mn:
    height = mx.z - mn.z
    res["height_before"] = round(height, 2)
    if height > 30 or height < 0.5:
        factor = (5.0 / height) if height > 0 else 1.0
        for o in bpy.data.objects:
            if o.parent is None:
                o.scale = o.scale * factor
                o.location = o.location * factor
        bpy.context.view_layer.update()
        res["scaled_factor"] = round(factor, 3)

# Drop images that never resolved (size 0) so pack_all doesn't choke on them.
for _img in list(bpy.data.images):
    if _img.size[0] == 0 and _img.source == 'FILE':
        try:
            bpy.data.images.remove(_img)
        except Exception:
            pass

try:
    bpy.ops.file.pack_all()
    res["packed"] = True
except Exception as e:
    res["packed"] = False
    res["pack_err"] = str(e)[:200]

out_fbx = os.path.join(OUTDIR, NAME + ".fbx")
try:
    bpy.ops.export_scene.fbx(
        filepath=out_fbx, path_mode='COPY', embed_textures=True,
        use_selection=False, bake_anim=False,
        object_types={'MESH', 'ARMATURE', 'EMPTY'},
        axis_forward='-Z', axis_up='Y',
    )
    res["fbx_size"] = os.path.getsize(out_fbx) if os.path.exists(out_fbx) else -1
except Exception as e:
    res["error"] = f"export failed: {e!r}"
    emit()

try:
    scene = bpy.context.scene
    mn2, mx2 = combined_bbox()
    center = (mn2 + mx2) / 2 if mn2 else mathutils.Vector((0, 0, 0))
    size = max((mx2 - mn2).x, (mx2 - mn2).y, (mx2 - mn2).z, 1.0) if mn2 else 5.0
    cam_d = bpy.data.cameras.new("C")
    cam = bpy.data.objects.new("C", cam_d)
    scene.collection.objects.link(cam)
    cam.location = center + mathutils.Vector((size * 1.4, -size * 1.8, size * 0.5))
    cam.rotation_euler = (center - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scene.camera = cam
    ld = bpy.data.lights.new("S", type='SUN')
    ld.energy = 3.0
    lo = bpy.data.objects.new("S", ld)
    scene.collection.objects.link(lo)
    lo.rotation_euler = (math.radians(55), 0, math.radians(40))
    w = scene.world or bpy.data.worlds.new("W")
    scene.world = w
    w.use_nodes = True
    bgn = w.node_tree.nodes.get("Background")
    if bgn:
        bgn.inputs[0].default_value = (0.05, 0.05, 0.06, 1.0)
    for eng in ('BLENDER_EEVEE_NEXT', 'BLENDER_EEVEE', 'BLENDER_WORKBENCH'):
        try:
            scene.render.engine = eng
            break
        except Exception:
            continue
    try:
        scene.eevee.taa_render_samples = 16
    except Exception:
        pass
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    out_png = os.path.join(OUTDIR, NAME + "_preview.png")
    scene.render.filepath = out_png
    scene.render.image_settings.file_format = 'PNG'
    bpy.ops.render.render(write_still=True)
    res["png_size"] = os.path.getsize(out_png) if os.path.exists(out_png) else -1
except Exception as e:
    res["render_err"] = repr(e)

emit()
