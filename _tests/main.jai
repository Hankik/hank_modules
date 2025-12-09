#import "obj2";
#import "Basic";
#import "Windows";

#add_context test_tag_type_handle : Tag_Type_Handle;

tests : [1]Test_Tag;
tests_objs : [..]Obj_Handle;

make_test :: () -> Tag_Handle {
    tests[0] = Test_Tag.{};
    return .{0, context.test_tag_type_handle};
}

get_test_tags :: () -> []Tag {
    return make_view(tests, Tag);
}

get_test_objs :: () -> []Obj_Handle {
    return make_view(tests_objs, Obj_Handle);
}


init_test_tags :: () {
    context.test_tag_type_handle = register_tag(
        Tag_Type_Data.{
            tag_type_info = type_info(Test_Tag),
            get_tags = get_test_tags,
            make_fn = make_test, 
            update_fn = update_fn,
            draw_fn = draw_fn,
            objs = *tests_objs,
        }
    );
}

update_fn :: (t: *Tag, dt: float) { }//print("haha\n"); }
draw_fn :: (t: *Tag) {}

main :: () {
    // distinguishing order establishes handle index
    init_objs();
    init_test_tags();
    
    _, obj := make_obj(tags=.[make_test()]);
    objs := find_objs_with_tags(context.test_tag_type_handle);
    print("%\n", FormatInt.{value=context.obj_data.obj_array[0].flags, base=2});
    using context.obj_data;
    while true {
        for registered_tag_types {
            if it.update_fn {
                for tag: it.get_tags() {
                    if tag.enabled {
                        it.update_fn(*tag, 0.1);
                    }
                }
            }
        }
        for registered_tag_types {
            if it.draw_fn {
                for tag: it.get_tags() {
                    it.draw_fn(*tag);
                    // print("%\n", it.get_tags().count);
                }
            }
        }
        Sleep(100);
    }
    
}