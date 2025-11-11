#import "Basic";
#import "Math";
#import "Hash_Table";
#import "Sort";

#add_context id_counter : int = 0;
#add_context obj_table : Table(Key_Type=int, Value_Type=*Obj);
#add_context obj_array : *[1024 * 16]Obj;
#add_context tagged_obj_table : *Table(Key_Type=string, Value_Type=*[..]Handle(Obj));
#add_context empty_obj_handle_arr : *[..]Handle(Obj) = ---;

setup_obj_module :: () {
    context.obj_array = New([1024 * 16]Obj);
    context.tagged_obj_table = New(Table(Key_Type=string, Value_Type=*[..]Handle(Obj)));
    context.empty_obj_handle_arr = New([..]Handle(Obj));
}

Handle :: struct (return_type:Type) {
    index: int = -1;
    type: Type : return_type;
}


operator == :: (x: Handle(Obj), y: Handle(Obj)) -> bool {
    return x.index == y.index;
}

Obj :: struct {
    handle : Handle(Obj);
    parent : Handle(Obj);
    local_pos : Vector2;
    children : *[..]Handle(Obj);
    tags : *[..]*Tag;
    enabled : bool = false;
    draw_layer : int = 0;
}

make_obj :: (position : Vector2 = .{0,0}, children : []*Obj = *Obj.[], tags : []*Tag = *Tag.[]) -> Handle(Obj), *Obj {
    obj := *context.obj_array.*[context.id_counter];
    obj.* = Obj.{};
    obj.local_pos = position;
    obj.handle = Handle(Obj).{index=context.id_counter};
    obj.enabled = true;
    context.id_counter = obj.handle.index + 1;
    obj.children = New([..]Handle(Obj));
    obj.tags = New([..]*Tag);
    for child : children { 
        array_add(obj.children, child.handle);
        child.parent = obj.handle;
    }
    add_obj_tags(obj, tags);
    print("new obj with id: %\n", obj.handle);
    return obj.handle, obj;
}

remove_obj :: (obj : *Obj) {
    // handle := obj.handle;
    msg_down(obj.handle, OnRemoveMsg.{});
    for index : 0..obj.tags.count-1 {
        tag := obj.tags.*[index];
        _, bucket := table_find_new(context.tagged_obj_table, tag.tag_type);
        for handle, i : bucket.* {
            if obj.handle == handle {
                array_unordered_remove_by_index(bucket, i);
                break;
            }
        }
        free(tag);
    } 
    for child_handle : obj.children.* {
        found_child, child := find_obj(child_handle);
        if found_child remove_obj(child);
    } 
    found_parent, parent := find_obj(obj.parent);
    if found_parent { 
        for parent_child_handle, index : parent.children.* {
            if parent_child_handle == obj.handle {
                array_ordered_remove_by_index(parent.children, index);
                break;
            }
            
        }
     }
    //table_remove(*context.obj_table, obj.handle.index);
    free(obj.tags);
    free(obj.children);
    obj.enabled = false;
    print("[H]: obj with handle % has been removed successfully\n", obj.handle);
    // free(obj);
}

add_obj_tags :: (obj: *Obj, tags: []*Tag) {
    for tag : tags {
        array_add(obj.tags, tag); 
        tag.obj = obj.handle;
        found_bucket, bucket := table_find_new(context.tagged_obj_table, tag.tag_type);
        if found_bucket {
            array_add(bucket, obj.handle);
        } else {
            bucket := New([..]Handle(Obj));
            array_add(bucket, obj.handle);
            table_add(context.tagged_obj_table, tag.tag_type, bucket);

        }
    }
}

get_objs_with_tag :: ($tag_type : Type) -> *[]Handle(Obj) {
    success, bucket := table_find_new(context.tagged_obj_table, type_info(tag_type).name);
    if success {
        return bucket;
    } else {
        return context.empty_obj_handle_arr;
    }
}

find_obj :: (handle : Handle(Obj)) -> success: bool, *Obj {
    if (handle.index >= 0) {
        obj := *context.obj_array.*[handle.index];
        return obj.enabled, (ifx obj.enabled then obj else null);
    } else {
        return false, null;
    }
    
}

// find_obj_tag :: (obj: *Obj, $tag_type: Type) -> bool, *tag_type {
//     for tag : obj.tags.* {
//         if tag.tag_type == type_info(tag_type).name { return true, cast(*tag_type) tag; }
//     }
//     return false, null;
//     // success, tag := table_find_new(obj.tags, type_info(tag_type).name);
//     // return success, cast(*tag_type) tag;
// }

find_obj_tag :: (obj_handle: Handle(Obj), $tag_type: Type) -> bool, *tag_type {
    found, obj := find_obj(obj_handle);
    if found {
        for tag : obj.tags.* {
            if tag.tag_type == type_info(tag_type).name { return true, cast(*tag_type) tag; }
        }
    }
    return false, null;
}

find_child_by_tag :: (obj_handle: Handle(Obj), $tag_type: Type) -> bool, *Obj, *tag_type {
    found, obj := find_obj(obj_handle);
    for child_handle : obj.children.* {
        success, tag := find_obj_tag(child_handle, tag_type);
        found_child, child := find_obj(child_handle);
        if success return true, child, tag;
        
    }
    return false, null, null;
}

find_children_with_tag :: (obj: *Obj, $tag_type: Type, recursive: bool = false) -> []*Obj {
    found_children : [..]*Obj;
    for child : obj.children.* {
        success := find_obj_tag(child, tag_type);
        if success array_add(*found_children, child);
    }
    return found_children;
}

// get_global_pos :: (obj : *Obj) -> Vector2 {
//     sum := obj.local_pos;
//     current_parent := obj.parent;
//     while current_parent {
//         sum += current_parent.local_pos;
//         current_parent = current_parent.parent;
//     }
//     return sum;
// }

get_global_pos :: (obj_handle: Handle(Obj)) -> Vector2 {
    found, obj := find_obj(obj_handle);
    sum := obj.local_pos;
    found_parent, current_parent := find_obj(obj.parent);
    while found_parent {
        sum += current_parent.local_pos;
        found_parent, current_parent = find_obj(current_parent.parent);
    }
    return sum;
}

set_global_pos :: (obj_handle: Handle(Obj), position: Vector2) {
    found, obj := find_obj(obj_handle);
    difference := position - get_global_pos(obj_handle);
    obj.local_pos += difference;
}

set_local_pos :: (obj_handle: Handle(Obj), position: Vector2) {
    found, obj := find_obj(obj_handle);
    obj.local_pos = position;
}

get_local_pos :: (obj_handle: Handle(Obj)) -> Vector2 {
    found, obj := find_obj(obj_handle);
    return obj.local_pos;
}

get_parent :: (obj_handle: Handle(Obj)) -> Handle(Obj) {
    found, obj := find_obj(obj_handle);
    return obj.parent;
}

add_child :: (parent: *Obj, child : *Obj) {
    array_add(parent.children, child);
    child.parent = parent;
}

add_child :: (parent_handle: Handle(Obj), child_handle : Handle(Obj)) {
    _, parent := find_obj(parent_handle);
    _, child := find_obj(child_handle);
    array_add(parent.children, child_handle);
    child.parent = parent_handle;
}


obj_tick :: (obj_handle: Handle(Obj), dt: float) {
    found, obj := find_obj(obj_handle);
    if obj.enabled {
        for tag : obj.tags.* if tag.enabled { tag.tick_fn(tag, dt); }
        for i : 0..obj.children.count-1 {
            child_handle := obj.children.*[i];
            obj_tick(child_handle, dt);
        } 
    }
}


obj_draw :: (obj_handle: Handle(Obj)) {
    found, obj := find_obj(obj_handle);
    if obj.enabled {
        for tag : obj.tags.* if tag.visible && tag.enabled tag.draw_fn(tag);
        for child_handle : quick_sort( 
            obj.children.*, 
            (a: Handle(Obj), b: Handle(Obj)) -> int {
                _, a_obj := find_obj(a);
                _, b_obj := find_obj(b);
                if a_obj.draw_layer < b_obj.draw_layer return -1;
                else {
                    if get_global_pos(a).y < get_global_pos(b).y return -1;
                    else return 1; }
                }
        ) {
            obj_draw(child_handle);
        }
    }
}

msg_to :: (obj_handle : Handle(Obj), msg : *Msg) -> bool {
    found, obj := find_obj(obj_handle);
    if obj.enabled {
        for tag : obj.tags.* {
            if tag.enabled {
                consumed := tag.on_get_msg_fn(tag, msg);
                if consumed return true;
            }
        }
    }
    
    return false;
}

msg_up :: (obj_handle: Handle(Obj), msg: *Msg) -> bool {
    found, obj := find_obj(obj_handle);
    if obj.enabled {
        for tag : obj.tags.* {
            if tag.enabled {
                consumed := tag.on_get_msg_fn(tag, msg);
                if consumed return true;
            }
        }
        if obj.parent {
            consumed := msg_up(obj.parent, msg);
            if consumed return true;
        }
    }
    
    return false;
}

msg_down :: (obj_handle: Handle(Obj), msg: *Msg) -> bool {
    found, obj := find_obj(obj_handle);
    if found && obj.enabled {
        for tag : obj.tags.* {
            if tag.enabled {
                consumed := tag.on_get_msg_fn(tag, msg);
                if consumed return true;
            }
        }
        for i : 0..obj.children.count-1 {
            child_handle := obj.children.*[i]; 
            consumed := msg_down(child_handle, msg);
            if consumed return true;
            
        }
    }
    
    return false;
}


Tag :: struct {
    tag_type : string = "Tag";
    obj : Handle(Obj);
    tick_fn : (tag: *Tag, dt: float) = tag_tick;
    draw_fn : (tag: *Tag) = tag_draw;
    on_get_msg_fn : (tag: *Tag, msg: *Msg) -> bool = on_tag_get_msg;
    enabled : bool = true;
    visible : bool = true;
}

Mask :: struct ($T : Type) {
    type : Type : T;
    current : T;
    original : T;
}

make_mask :: ($T: Type) -> *Mask(T) {
    mask := New(Mask(T));
    mask.current = T.{};
    mask.original = T.{};
    return mask;
}

tag_tick :: (tag: *Tag, dt: float) {}
tag_draw :: (tag: *Tag) {}
on_tag_get_msg :: (tag: *Tag, msg: *Msg) -> bool { return false; }

Msg :: struct {
    type : Type = Msg;
}

OnBeginMsg :: struct {
    #as using msg: Msg;
    type = OnBeginMsg;
}

OnRemoveMsg :: struct {
    #as using msg: Msg;
    type = OnRemoveMsg;
}



#scope_file
#import "Hash_Table";