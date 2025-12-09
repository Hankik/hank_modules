#import "Basic";
#import "Math";

#module_parameters(MAX_CHILDREN := 16, MAX_TAGS := 32);

#add_context obj_data : *Obj_Data;

Handle :: #type, isa int;
Obj_Handle :: #type, distinct Handle;
Tag_Handle :: struct {
    index : int = -1;
    type: Tag_Type_Handle = -1;
}
Tag_Type_Handle :: #type, distinct Handle;
Pair :: struct (one : $T, two: $U) { a: one; b: two; }
TAG_CREATE_FN_TYPE :: #run type_of(()->Tag_Handle{return .{0, 0};});

init_objs :: () {
    context.obj_data = New(Obj_Data);
    context.obj_data.* = Obj_Data.{};
}

Obj_Data :: struct {
    obj_id_counter : int = 0;
    obj_array : [1024 * 16]Obj;
    registered_tag_type_counter := 63;
    registered_tag_types : [64]Tag_Type_Data;
}

Obj :: struct {
    handle : Obj_Handle = -1;
    parent: Obj_Handle;
    position: Vector2;
    children : *[MAX_CHILDREN]Obj_Handle;
    tags : *[MAX_TAGS]Tag_Handle;
    flags := 0x0;
}

Tag :: struct {
    enabled: bool = true;
}

Msg :: struct {

}

Tag_Type_Data :: struct {
    type: Tag_Type_Handle = -1;
    tag_type_info : *Type_Info;
    make_fn : () -> Tag_Handle = null;
    update_fn : (tag: *Tag, dt: float) = null;
    draw_fn : (tag: *Tag) = null;
    get_msg_fn : (tag: *Tag, msg: *Msg) -> bool = null;
    get_tags : () -> []Tag = null; // swap out with data pointer?
    objs : *[..]Obj_Handle;
}

make_obj :: (children: []Obj_Handle = Obj_Handle.[], tags : []Tag_Handle = Tag_Handle.[]) -> Obj_Handle, *Obj {
    using context.obj_data;
    obj := *obj_array[obj_id_counter];
    obj.handle = obj_id_counter.(Obj_Handle);
    obj.children = New([MAX_CHILDREN]Obj_Handle);
    obj.tags = New([MAX_TAGS]Tag_Handle);
    add_children(obj, children);
    add_tags(obj, tags);
    obj_id_counter += 1;
    return obj.handle, obj;
}

add_children :: (obj: *Obj, obj_handles: []Obj_Handle) {
    for obj_handles {
        obj.children.*[it_index] = it;
        found_child, child := find(it);
        if found_child child.parent = obj.handle;
    }
}

add_tags :: (obj: *Obj, tag_handles: []Tag_Handle) {
    for tag_handles {
        found_type, tag_type_data := find_tag_type_data(it);
        if found_type {
            obj.tags.*[it_index] = it;
            obj.flags |= (1 << it.type);
            array_add(tag_type_data.objs, obj.handle);
        }
    }
}

find_tag_type_data :: (tag_handle: Tag_Handle) -> bool, Tag_Type_Data {
    if tag_handle.type >= 0
        return true, context.obj_data.registered_tag_types[tag_handle.type];
    else
        return false, Tag_Type_Data.{};
}

get_global_pos :: (obj: *Obj) -> Vector2 {
    sum := obj.position;
    found_parent, parent := find(obj.parent);
    while found_parent {
        sum += parent.position;
        found_parent, parent = find(parent.parent);
    }
}

get_global_pos :: (obj_handle: Obj_Handle) {
    found, obj := find(obj_handle);
    return get_global_pos(obj);
}

set_global_pos :: (obj_handle: Obj_Handle, new_position: Vector2) {
    found, obj := find(obj_handle);
    difference := position - get_global_pos(obj);
    obj.position += difference;
}

set_local_pos :: (obj_handle: Obj_Handle, position: Vector2) {
    found, obj := find(obj_handle);
    obj.position = position;
}

get_local_pos :: (obj_handle: Obj_Handle) -> Vector2 {
    found, obj := find(obj_handle);
    return obj.position;
}

find :: (handle: Obj_Handle) -> bool, *Obj {
    if handle >= 0 && handle < MAX_CHILDREN
        return true, *context.obj_data.obj_array[handle];
    else return false, null;
}

find :: (tag_handle: Tag_Handle) -> bool, *Tag {
    using context.obj_data;
    if tag_handle.index >= 0 {
        return true, *registered_tag_types[tag_handle.type].get_tags()[tag_handle.index];
    } else {
        return false, null;
    }
}

get_parent :: (obj_handle: Obj_Handle) -> Obj_Handle {
    found, obj := find(obj_handle);
    return obj.parent;
}

find_objs_with_tag :: (tag_type: Tag_Type_Handle) -> []Obj_Handle {
    using context.obj_data;
    return make_view(registered_tag_types[tag_type].objs);
}

find_objs_with_tags :: (tags: ..Tag_Type_Handle) -> []Obj_Handle {
    using context.obj_data;
    required_flags := 0x0;
    for tags {
        required_flags |= (1 << it);
    }
    found_objs: [..]Obj_Handle;
    found_objs.allocator = temp;
    for obj_array {
        if it.flags & required_flags {
            array_add(*found_objs, it.handle);
        }
    }
    return found_objs;
}

find_child_by_tag :: (obj_handle: Obj_Handle, tag_type : Tag_Type_Handle) -> bool, *Obj, Tag_Handle {
    obj := find(obj_handle);
    for obj.children {
        found_tag, tag, child := find_obj_tag(it, tag_type);
        if found_tag return true, child, tag;
    }
    return false, null, null;
}


find_obj_tag :: (obj_handle: Obj_Handle, tag_type_handle: Tag_Type_Handle) -> bool, *Tag, *Obj {
    obj := find_obj(obj_handle);
    // if obj.tag_flags & (1 << tag_type_handle.(u32)) { }
    for obj.tags {
        if it.type == tag_type_handle {
            found_tag, tag := find_tag(it, tag_type_handle);
            if found_tag return true, tag, obj;
        }
    }
    return false, null, null;
}

Test_Tag :: struct {
    #as using tag: Tag;
}

register_tag :: (tag_data : Tag_Type_Data) -> Tag_Type_Handle {
    using context.obj_data;
    index := registered_tag_type_counter;
    registered_tag_types[index] = tag_data;
    registered_tag_type_counter += 1;
    return index.(Tag_Type_Handle);
}

make_view :: (arr: []$T, $new_type: Type) -> []new_type {
    view : []new_type;
    view.data = cast(*new_type) arr.data;
    view.count = arr.count;
    return view;
}
