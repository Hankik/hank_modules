Simp :: #import "Simp";
#import "Math";

DrawSettings :: struct {
    fill : Vector4 = .{1.0,1.0,1.0,1.0};
    stroke : Vector4 = .{.0,.0,.0,.0};
    stroke_width : float = 2.0;
    fill_enabled : bool = true;
    stroke_enabled : bool = true;
}

#add_context draw_settings := DrawSettings.{};

circle :: (position: Vector2, radius: float, segments: s32 = 20) {
    Simp.set_shader_for_color();
    using context.draw_settings;
    //Simp.CheckSpace(segments);
    if fill_enabled {
        center_uv : Vector2 = .{0.5, 0.5};
        for i : 0..segments-1 {
            // Center vertex
            Simp.immediate_vertex(.{position.x, position.y, 0.0}, fill, center_uv, .{});
            
            // Current perimeter vertex
            angle1 := 2 * 3.14159 * i / segments;
            x1 := position.x + radius * cos(angle1);
            y1 := position.y + radius * sin(angle1);
            uv1 : Vector2 = .{(cos(angle1) * 0.5) + 0.5, (sin(angle1) * 0.5) + 0.5};
            Simp.immediate_vertex(.{x1, y1, 0.0}, fill, uv1, .{});
            
            // Next perimeter vertex
            angle2 := 2 * 3.14159 * (i + 1) / segments;
            x2 := position.x + radius * cos(angle2);
            y2 := position.y + radius * sin(angle2);
            uv2 : Vector2 = .{(cos(angle2) * 0.5) + 0.5, (sin(angle2) * 0.5) + 0.5};
            Simp.immediate_vertex(.{x2, y2, 0.0}, fill, uv2, .{});
        }
    }
    
    if stroke_enabled {
        for i : 0..segments-1 {
            // Center vertex
            
            // Current perimeter vertex
            angle1 := 2 * 3.14159 * i / segments;
            x1 := position.x + radius * cos(angle1);
            y1 := position.y + radius * sin(angle1);
            
            // Next perimeter vertex
            angle2 := 2 * 3.14159 * (i + 1) / segments;
            x2 := position.x + radius * cos(angle2);
            y2 := position.y + radius * sin(angle2);
            mid_point := .{x1 + x2, y1 + y2} * 0.5;
            line_normal := normalize(Vector2.{mid_point.x - position.x, mid_point.y - position.y});
            line_dir := Vector2.{-line_normal.y, line_normal.x};
            Simp.immediate_quad(
                .{x1, y1} - line_dir + line_normal * stroke_width * 0.5,
                .{x1, y1} - line_dir - line_normal * stroke_width * 0.5,
                .{x2, y2} - line_normal * stroke_width * 0.5,
                .{x2, y2} + line_normal * stroke_width * 0.5,
                stroke
            );
        }
    }
    
}

image :: (texture: *Simp.Texture, position: Vector2, size: Vector2) {
    Simp.set_shader_for_images(texture);
    old_settings := context.draw_settings;
    context.draw_settings.fill_enabled = true;
    Simp.immediate_quad(
        position.x - size.x * 0.5,
        position.y - size.y * 0.5,
        position.x + size.x * 0.5,
        position.y + size.y * 0.5,
        context.draw_settings.fill
    );
    context.draw_settings = old_settings;
}

rect :: (position: Vector2, size: Vector2) {
    Simp.set_shader_for_color();
    using context.draw_settings;
    if context.draw_settings.fill_enabled {
        Simp.immediate_quad(
            position.x - size.x * 0.5,
            position.y - size.y * 0.5,
            position.x + size.x * 0.5,
            position.y + size.y * 0.5,
            fill
        );
    }
    if context.draw_settings.stroke_enabled {
        Simp.immediate_quad(
            position.x - size.x * 0.5 - stroke_width * 0.5,
            position.y - size.y * 0.5 - stroke_width * 0.5,
            position.x + size.x * 0.5 + stroke_width * 0.5,
            position.y - size.y * 0.5 + stroke_width * 0.5,
            stroke
        );
        Simp.immediate_quad(
            position.x + size.x * 0.5 - stroke_width * 0.5,
            position.y - size.y * 0.5,
            position.x + size.x * 0.5 + stroke_width * 0.5,
            position.y + size.y * 0.5,
            stroke
        );
        Simp.immediate_quad(
            position.x - size.x * 0.5 - stroke_width * 0.5,
            position.y + size.y * 0.5 + stroke_width * 0.5,
            position.x + size.x * 0.5 + stroke_width * 0.5,
            position.y + size.y * 0.5 - stroke_width * 0.5,
            stroke
        );
        Simp.immediate_quad(
            position.x - size.x * 0.5 - stroke_width * 0.5,
            position.y - size.y * 0.5,
            position.x - size.x * 0.5 + stroke_width * 0.5,
            position.y + size.y * 0.5,
            stroke
        );
    }
    
}