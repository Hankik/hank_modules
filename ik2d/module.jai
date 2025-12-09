#import "Math";
#import "Basic";
#import "Hash_Table";

#add_context joints_table : *Table(string, []Joint);

init_ik2d :: () {
    context.joints_table = New(Table(string, []Joint));
}

Joint :: struct {
    position: Vector2;
    length_to_next: float;
}

// save_joints :: (key: string, joints: []Joint) {
//     if !table_find(context.joints_table, key) { 
//         table_add(context.joints_table, key, joints);
//         print("TEST");
//     }
// }

solve_fabrik :: (joints: []Joint, key: string, target: Vector2, tolerance: float = 0.01, max_iters: int = 6) {
    found, saved := table_find(context.joints_table, key);
    if found {
        solve_fabrik(joints, target, *saved, tolerance, max_iters);
    }
}
 
solve_fabrik :: (joints_source: []Joint, target: Vector2, eased: bool = false, tolerance: float = 0.01, max_iters: int = 6) {
    //if joints.count < 2 return;                                             
    joints := array_copy(joints_source);
    defer array_free(joints);
    root_pos := joints[0].position;
    total_len := 0.0;
    for 0..joints.count-1 {
        total_len += joints[it].length_to_next;
    }

    dist_to_target := length(target - root_pos);

    target_unreachable := dist_to_target > total_len;
    if target_unreachable {
        dir := normalize(target - root_pos);
        for 0..joints.count-2 {
            joints[it + 1].position = joints[it].position + dir * joints[it].length_to_next;
        }
    } else {
        for iter: 0..max_iters-1 {
            joints[joints.count-1].position = target;
            for < 1..joints.count-1 {
                current_dist := length(joints[it-1].position - joints[it].position);
                stretch_ratio := joints[it].length_to_next / current_dist;
                joints[it].position = joints[it-1].position * (1 - stretch_ratio) + joints[it].position * stretch_ratio;
            }

            joints[0].position = root_pos;
            for 0..joints.count-2 {
                current_dist := length(joints[it+1].position - joints[it].position);
                stretch_ratio := joints[it].length_to_next / current_dist;
                joints[it].position = joints[it+1].position * (1 - stretch_ratio) + joints[it].position * stretch_ratio;
            }

            end_joint_pos := joints[joints.count-1].position;
            if length(end_joint_pos - target) < tolerance break;
        }

    }

    for joints {
        delta := it.position - joints_source[it_index].position;
        joints_source[it_index].position = ifx eased then {
                lerp(joints_source[it_index].position, joints_source[it_index].position + delta, context.delta_time * 12.0);
        }
        else
            it.position;
    }
    
}