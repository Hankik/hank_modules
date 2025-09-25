#import "Basic";
#import "Math";
#import "Hash_Table";
#import "Sort";

#add_context id_counter : int = 0;
#add_context obj_table : Table(Key_Type=int, Value_Type=*Obj);

Obj :: struct {
    id : int;
    parent : *Obj;
    local_pos : Vector2;
    children : *[..]*Obj;
    tags : *[..]*Tag;
    enabled : bool = true;
    draw_layer : int = 0;
}

make_obj :: (position : Vector2 = .{0,0}, children : []*Obj = *Obj.[], tags : []*Tag = *Tag.[]) -> *Obj{
    obj := New(Obj);
    obj.local_pos = position;
    obj.id = context.id_counter;
    table_add(*context.obj_table, obj.id, obj);
    context.id_counter = obj.id + 1;
    obj.children = New([..]*Obj);
    obj.tags = New([..]*Tag);
    for child : children { 
        array_add(obj.children, child);
        child.parent = obj;
    }
    for tag : tags {
        array_add(obj.tags, tag); 
        tag.obj = obj;
    }
    print("new obj with id: %\n", obj.id);
    return obj;
}

remove_obj :: (obj : *Obj) {
    id := obj.id;
    for tag : obj.tags.* free(tag);
    for child : obj.children.* remove_obj(child);
    if obj.parent != null { array_unordered_remove_by_value(obj.parent.children, obj, true); }
    free(obj.tags);
    free(obj.children);
    free(obj);
    print("[H]: obj with id % has been removed successfully\n", id);
}

find_obj_tag :: (obj: *Obj, $tag_type: Type) -> bool, *tag_type {
    for tag : obj.tags.* {
        if tag.tag_type == type_info(tag_type).name { return true, cast(*tag_type) tag; }
    }
    return false, null;
    // success, tag := table_find_new(obj.tags, type_info(tag_type).name);
    // return success, cast(*tag_type) tag;
}

find_child_by_tag :: (obj: *Obj, $tag_type: Type) -> bool, *Obj, *tag_type {
    for child : obj.children.* {
        success, tag := find_obj_tag(child, tag_type);
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

get_global_pos :: (obj : *Obj) -> Vector2 {
    sum := obj.local_pos;
    current_parent := obj.parent;
    while current_parent {
        sum += current_parent.local_pos;
        current_parent = current_parent.parent;
    }
    return sum;
}

set_global_pos :: (obj: *Obj, position: Vector2) {
    difference := position - get_global_pos(obj);
    obj.local_pos += difference;
}

add_child :: (parent: *Obj, child : *Obj) {
    array_add(parent.children, child);
    child.parent = parent;
}


obj_tick :: (obj: *Obj, dt: float) {
    for tag : obj.tags.* if tag.enabled { tag.tick_fn(tag, dt); }
    for i : 0..obj.children.count-1 {
        child := obj.children.*[i];
        if child.enabled obj_tick(child, dt);
    } 
    
}

obj_draw :: (obj: *Obj) {
    for tag : obj.tags.* if tag.visible && tag.enabled tag.draw_fn(tag);
    for child : quick_sort( 
        obj.children.*, 
        (a: *Obj, b: *Obj) -> int {
            if a.draw_layer < b.draw_layer return -1;
            else {
                if get_global_pos(a).y < get_global_pos(b).y return -1;
                else return 1; }
            }
    ) {
        if child.enabled obj_draw(child);
    }
}

msg_to :: (obj : *Obj, msg : *Msg) -> bool {
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

msg_up :: (obj: *Obj, msg: *Msg) -> bool {
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

msg_down :: (obj: *Obj, msg: *Msg) -> bool {
    if obj.enabled {
        for tag : obj.tags.* {
            if tag.enabled {
                consumed := tag.on_get_msg_fn(tag, msg);
                if consumed return true;
            }
        }
        for i : 0..obj.children.count-1 {
            child := obj.children.*[i]; 
            consumed := msg_down(child, msg);
            if consumed return true;
        }
    }
    
    return false;
}

Tag :: struct {
    tag_type : string = "Tag";
    obj : *Obj;
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



#scope_file
#import "Hash_Table";