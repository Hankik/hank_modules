#import "Math";

push :: () {
    using context.draw_settings;
    top_matrix := transform_stack.*[transform_stack_top];
    transform_stack_top += 1;
    transform_stack.*[transform_stack_top] = top_matrix;
}

pop :: () {
    using context.draw_settings;
    transform_stack_top -= 1;
}

rotate :: (theta : float, axis : Vector3 = .{z=1.0}) {
    using context.draw_settings;

    top := transform_stack.*[transform_stack_top];
    q := Quaternion.{};
    set_from_axis_and_angle(*q, axis, theta);
    m := rotation_matrix(Matrix4, q);
    transform_stack.*[transform_stack_top] = top * m;
}

scale :: (new_scale: Vector2) {
    using context.draw_settings;
    top := transform_stack.*[transform_stack_top];
    m := make_scale_matrix4(.{new_scale.x, new_scale.y, 1.0});
    transform_stack.*[transform_stack_top] = top * m;
}

translate :: (translation : Vector2) {
    using context.draw_settings;
    top := transform_stack.*[transform_stack_top];

    m := make_translation_matrix4(.{translation.x, translation.y, 0.0});

    transform_stack.*[transform_stack_top] = top * m;
}