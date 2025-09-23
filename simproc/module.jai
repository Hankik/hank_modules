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

rect :: (position: Vector2, size: Vector2) {
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