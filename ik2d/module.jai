#import "Math";

Joint :: struct {
    position: Vector2;
    length_to_next: float;
}

solve_fabrik :: (joints: []Joint, target: Vector2, tolerance: float = 0.01, max_iters: int = 6) {
    //if joints.count < 2 return;
    root_pos := joints[0].position;
    total_len := 0.0;
    for 0..joints.count-2 {
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
            for #v2 < 1..joints.count-1 {
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
}