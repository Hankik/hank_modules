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

rotate :: (theta : float) {
    using context.draw_settings;

    top := transform_stack.*[transform_stack_top];
    axis := Vector3.{z=1.0};
    q := Quaternion.{};
    set_from_axis_and_angle(*q, axis, theta);
    m := rotation_matrix(Matrix3, q);
    transform_stack.*[transform_stack_top] = top * m;
}

scale :: (new_scale: Vector2) {
    using context.draw_settings;
    scale(
        *transform_stack.*[transform_stack_top], // matrix3 pointer
        Vector3.{new_scale.x, new_scale.y, 0.0}  // vector3 value
    );
}

translate :: (translation : Vector2) {
    using context.draw_settings;
    top_matrix := transform_stack.*[transform_stack_top];

    // Directly add translation
    top_matrix._13 += translation.x;
    top_matrix._23 += translation.y;

    transform_stack.*[transform_stack_top] = top_matrix;
}