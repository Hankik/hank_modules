Simp :: #import "Simp";
#import "Basic";
#import "Math";

#add_context draw_settings := DrawSettings.{};

MAX_TRANSFORM_STACK_SIZE :: 64;

WHITE :: Vector4.{1.,1.,1.,1.};
BLACK :: Vector4.{0.,0.,0.,1.};
GRAY :: Vector4.{.5,.5,.5,1.};

DrawSettings :: struct {
    fill : Vector4 = .{1.0,1.0,1.0,1.0};
    stroke : Vector4 = .{.0,.0,.0,.0};
    stroke_width : float = 2.0;
    fill_enabled : bool = true;
    stroke_enabled : bool = true;
    font : *Simp.Dynamic_Font = null;
    text_size : float = 14.0;

    transform_stack: *[MAX_TRANSFORM_STACK_SIZE]Matrix3;    // dynamic array of matrices
    transform_stack_top: int = 0;
}

init_simproc :: () {
    using context.draw_settings;
    transform_stack = New([MAX_TRANSFORM_STACK_SIZE]Matrix3);
    transform_stack.*[0] = Matrix3_Identity;
}

fill :: (color: Vector4) {
    context.draw_settings.fill = color;
    context.draw_settings.fill_enabled = true;
}

stroke :: (color: Vector4) {
    context.draw_settings.stroke = color;
    context.draw_settings.stroke_enabled = true;
}

font :: (font: *Simp.Dynamic_Font) {
    context.draw_settings.font = font;
}

stroke_width :: (width : float) {
    context.draw_settings.stroke_width = width;
}

no_fill :: () {
    context.draw_settings.fill_enabled = false;
}

no_stroke :: () {
    context.draw_settings.stroke_enabled = false;
}


TextAlignment :: enum {
    LEFT;
    CENTER;
    RIGHT;
}

text :: (text: string, position: Vector2, alignment : TextAlignment = .CENTER) {
    using context.draw_settings;
    width := Simp.prepare_text(font, text);
    offset : s64;
    if alignment == {
        case .LEFT; offset = 0;
        case .RIGHT; offset = width;
        case .CENTER; offset = cast(s64) (width * 0.5);
    }
    Simp.draw_prepared_text(font, cast(s64) (position.x - offset), cast(s64) (position.y + font.y_offset_for_centering), fill);
    
}

circle :: (position: Vector2, radius: float, segments: s32 = 24) {
    Simp.set_shader_for_color();
    using context.draw_settings;
    ellipse(position, .{radius, radius}, segments);
}

image :: (texture: *Simp.Texture, position: Vector2, size: Vector2) {
    using context.draw_settings;
    Simp.set_shader_for_images(texture);
    old_settings := context.draw_settings;
    fill_enabled = true;
    transform := transform_stack.*[transform_stack_top];
    p0 := transform * Vector3.{position.x + size.x * 0.5, position.y + size.y * 0.5, 1};
    p1 := transform * Vector3.{position.x - size.x * 0.5, position.y + size.y * 0.5, 1};
    p2 := transform * Vector3.{position.x - size.x * 0.5, position.y - size.y * 0.5, 1};
    p3 := transform * Vector3.{position.x + size.x * 0.5, position.y - size.y * 0.5, 1};
    Simp.immediate_quad(
        p0,
        p1,
        p2,
        p3,
        context.draw_settings.fill
    );
    context.draw_settings = old_settings;
}

line :: (point_a: Vector2, point_b: Vector2, line_width : float = 2.0) {
    Simp.set_shader_for_color();
    using context.draw_settings;
    if stroke_enabled {
        transform := transform_stack.*[transform_stack_top];
        point_a_transformed := transform * Vector3.{point_a.x, point_a.y, 1.0};
        point_b_transformed := transform * Vector3.{point_b.x, point_b.y, 1.0};
        slope := normalize(point_a_transformed - point_b_transformed);
        normal := Vector3.{-slope.y, slope.x, 1.0};
        Simp.immediate_quad(
            point_a_transformed - normal * line_width*0.5,
            point_a_transformed + normal * line_width*0.5,
            point_b_transformed + normal * line_width*0.5,
            point_b_transformed - normal * line_width*0.5,
            stroke
        );
    }
}

rect :: (position: Vector2, size: Vector2) {
    Simp.set_shader_for_color();
    using context.draw_settings;
    if context.draw_settings.fill_enabled {
        transform := transform_stack.*[transform_stack_top];
        pos1 := transform * Vector3.{position.x - size.x * 0.5, position.y - size.y * 0.5, 1.0};
        pos2 := transform * Vector3.{position.x + size.x * 0.5, position.y - size.y * 0.5, 1.0};
        pos3 := transform * Vector3.{position.x + size.x * 0.5, position.y + size.y * 0.5, 1.0};
        pos4 := transform * Vector3.{position.x - size.x * 0.5, position.y + size.y * 0.5, 1.0};
        Simp.immediate_quad(
            pos1,
            pos2,
            pos3,
            pos4,
            fill
        );
    }
    if context.draw_settings.stroke_enabled {
        line(position - size * 0.5, position + .{size.x, -size.y} * 0.5, stroke_width);
        line(position + .{size.x, -size.y} * 0.5, position + size * 0.5, stroke_width);
        line(position + size * 0.5, position + .{-size.x, size.y} * 0.5, stroke_width);
        line(position + .{-size.x, size.y} * 0.5, position - size * 0.5, stroke_width);
    }
    
}

ellipse :: (position: Vector2, radii: Vector2, segments: int = 36) {
    using context.draw_settings;

    transform := transform_stack.*[transform_stack_top];
    step := (2.0 * PI) / cast(float)segments;
    if fill_enabled {
        //
        center_uv : Vector2 = .{0.5, 0.5};
        for i : 0..segments-1 {
            // Center vertex
            pos0 := transform * Vector3.{position.x, position.y, 1.0};
            Simp.immediate_vertex(pos0, fill, .{}, .{});
            
            // Current perimeter vertex
            angle1 := step * i.(float);
            x1 := position.x + radii.x * cos(angle1);
            y1 := position.y + radii.y * sin(angle1);
            //uv1 : Vector2 = .{(cos(angle1) * 0.5) + 0.5, (sin(angle1) * 0.5) + 0.5};
            pos1 := transform * Vector3.{x1, y1, 1.0};
            Simp.immediate_vertex(pos1, fill, .{}, .{z=1});
            
            // Next perimeter vertex
            angle2 := 2 * 3.14159 * (i + 1) / segments;
            x2 := position.x + radii.x * cos(angle2);
            y2 := position.y + radii.y * sin(angle2);
            //uv2 : Vector2 = .{(cos(angle2) * 0.5) + 0.5, (sin(angle2) * 0.5) + 0.5};
            pos2 := transform * Vector3.{x2, y2, 1.0};
            Simp.immediate_vertex(pos2, fill, .{}, .{z=1});
        }
    }
    if stroke_enabled {
        for i : 0..segments-1 {
            
            angle1 := step * i.(float);
            x1 := position.x + radii.x * cos(angle1);
            y1 := position.y + radii.y * sin(angle1);

            angle2 := 2 * 3.14159 * (i + 1) / segments;
            x2 := position.x + radii.x * cos(angle2);
            y2 := position.y + radii.y * sin(angle2);
            line(.{x1, y1}, .{x2, y2}, stroke_width);
        }
    }
}

triangle :: (point_a: Vector2, point_b: Vector2, point_c: Vector2) {

    using context.draw_settings;
    transform := transform_stack.*[transform_stack_top];
    point_a_transformed := transform * Vector3.{point_a.x, point_a.y, 1.0};
    point_b_transformed := transform * Vector3.{point_b.x, point_b.y, 1.0};
    point_c_transformed := transform * Vector3.{point_c.x, point_c.y, 1.0};

    if fill_enabled {
        Simp.immediate_triangle(
            point_a_transformed,
            point_b_transformed,
            point_c_transformed,
            fill,
            fill,
            fill,
        );
    }
    if stroke_enabled {
        line(point_a, point_b, stroke_width);
        line(point_b, point_c, stroke_width);
        line(point_c, point_a, stroke_width);
    }
}

#load "matrices.jai";