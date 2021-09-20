/*
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

public class Akira.ViewLayers.ViewLayerPath : ViewLayer {
    public const double UI_NOB_SIZE = 4;

    private Models.PathDataModel path_data;
    private Geometry.Rectangle old_live_extents;

    public void update_path_data (Models.PathDataModel _path_data) {
        path_data = _path_data;

        // Initial values for old extents of live effect will span the entire canvas.
        old_live_extents.left = old_live_extents.top = 0.0;
        old_live_extents.right = old_live_extents.bottom = 1000.0;

        update ();
    }

    public override void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {
        if (is_visible == false) {
            return;
        }

        if (canvas == null || path_data.points == null) {
            return;
        }

        if (path_data.extents.left > target_bounds.right || path_data.extents.right < target_bounds.left
            || path_data.extents.top > target_bounds.bottom || path_data.extents.bottom < target_bounds.top) {
            return;
        }

        draw_points (context);
        draw_live_effect (context);

        context.new_path ();
    }

    public override void update () {
        if (canvas == null || path_data.points == null) {
            return;
        }

        canvas.request_redraw (old_live_extents);
        canvas.request_redraw (path_data.live_extents);
        old_live_extents = path_data.live_extents;
    }

    private void draw_points (Cairo.Context context) {
        if (path_data.points == null) {
            return;
        }

        double radius = UI_NOB_SIZE / canvas.scale;

        context.save ();

        context.new_path ();
        context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);

        var extents = path_data.extents;
        var reference_point = Geometry.Point (extents.left, extents.top);
        var origin = Geometry.Point ( (extents.right - extents.left) / 2, (extents.bottom - extents.top) / 2);

        double sin_theta = Math.sin (path_data.rot_angle);
        double cos_theta = Math.cos (path_data.rot_angle);

        context.move_to (extents.left, extents.right);
        foreach (var pt in path_data.points) {
            // Apply the rotation formula and rotate the point by given angle
            double rot_x = cos_theta * (pt.x - origin.x) - sin_theta * (pt.y - origin.y) + origin.x;
            double rot_y = sin_theta * (pt.x - origin.x) + cos_theta * (pt.y - origin.y) + origin.y;

            context.arc (rot_x + reference_point.x, rot_y + reference_point.y, radius, 0, Math.PI * 2);
            context.fill ();
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }

    private void draw_live_effect (Cairo.Context context) {
        context.save ();

        context.new_path ();
        context.set_source_rgba (0, 0, 0, 1);
        context.set_line_width (1.0 / canvas.scale);

        var extents = path_data.extents;
        var reference_point = Geometry.Point (extents.left, extents.top);

        var points = path_data.points;
        var live_pts = path_data.live_pts;

        var last_point = points[points.length - 1];
        context.move_to (last_point.x + reference_point.x, last_point.y + reference_point.y);

        switch (path_data.length) {
            case 0: break;
            case 1: context.line_to (live_pts[0].x, live_pts[0].y);
                    break;
            case 2: break;
            case 3: var x0 = points[points.length - 1].x + reference_point.x;
                    var y0 = points[points.length - 1].y + reference_point.y;
                    var x1 = live_pts[0].x;
                    var y1 = live_pts[0].y;
                    var x2 = live_pts[1].x;
                    var y2 = live_pts[1].y;

                    context.curve_to (x0, y0, x2, y2, x1, y1);
                    break;
            case 4: var x0 = points[points.length - 1].x + reference_point.x;
                    var y0 = points[points.length - 1].y + reference_point.y;
                    var x1 = live_pts[0].x;
                    var y1 = live_pts[0].y;
                    var x2 = live_pts[1].x;
                    var y2 = live_pts[1].y;
                    var x3 = live_pts[2].x;
                    var y3 = live_pts[2].y;
                    var x4 = live_pts[3].x;
                    var y4 = live_pts[3].y;

                    context.curve_to (x0, y0, x2, y2, x1, y1);
                    context.curve_to (x1, y1, x3, y3, x4, y4);
                    break;

            default: break;
        }

        context.stroke ();
        context.new_path ();
        context.restore ();
    }
}
