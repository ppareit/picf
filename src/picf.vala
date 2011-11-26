/*
 * Copyright (C) Pieter Pareit 2011 <pieter.pareit@gmail.com>
 * 
 * deskpic is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * deskpic is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using Gtk;
using Cairo;

public class PicfSettings : GLib.Settings {
    public PicfSettings () {
        Object(schema: "be.ppareit.picf");
    }
}
//static GLib.Settings settings = new GLib.Settings ("be.ppareit.picf");

public class FloatWindow : Gtk.Window {

    PicfSettings settings = new PicfSettings ();
    
    bool ignore_reposition = false;
    bool ignore_resize = false;

    public FloatWindow () {
        Object(type: Gtk.WindowType.TOPLEVEL);
        
        this.title = "picf";
        
        reposition_from_settings ();
        resize_from_settings ();
        
        set_keep_below (true);
        skip_taskbar_hint = true;
        decorated = false;
        app_paintable = true;
        stick();
        resizable = true;
        
        Menu menu = new Menu ();
        var choose_menu = new MenuItem.with_label("Choose Picture");
        choose_menu.activate.connect (() => {
            var file_chooser = new FileChooserDialog ("Choose Picture", this,
                                        FileChooserAction.OPEN,
                                        Stock.CANCEL, ResponseType.CANCEL,
                                        Stock.OPEN, ResponseType.ACCEPT);
            if (file_chooser.run () == ResponseType.ACCEPT) {
                settings.set_string("path", file_chooser.get_filename ());
            }
            file_chooser.destroy ();
        });
        menu.append (choose_menu);
        menu.append (new SeparatorMenuItem ());
        var about_menu = new ImageMenuItem.from_stock(Stock.ABOUT, null);
        about_menu.activate.connect (() => {
            var about = new AboutDialog ();
            about.set_version ("0.0.1");
            about.set_program_name ("Destop picture frame");
            about.set_comments ("Displays a picture frame on the desktop");
            about.set_copyright ("Pieter Pareit");
            about.run ();
            about.hide ();
        });
        menu.append (about_menu);
        var quit_menu = new ImageMenuItem.from_stock(Stock.QUIT, null);
        quit_menu.activate.connect (Gtk.main_quit);
        menu.append (quit_menu);
        menu.show_all ();

        add_events (Gdk.EventMask.BUTTON_PRESS_MASK);

        button_press_event.connect ((e) => {
            // TODO: next is a hack to enable it to resize,
            // how to detect cleanly if pressed on the resize handle?
            if (e.button == 1) {
                if (e.x > 20 && e.y > 20) {
                    begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                    return true;
                }
            }
            else if (e.button == 3) {
                menu.popup (null, null, null, e.button, Gtk.get_current_event_time());
                return true;
            }
            return false;
        });
        
        
        configure_event.connect ((e) => {
            ignore_reposition = true;
            settings.set ("position", "(ii)", e.x, e.y);
            ignore_reposition = false;
            
            ignore_resize = true;
            settings.set ("size", "(ii)", e.width, e.height);
            ignore_resize = false;
            
            return false;
        });

        settings.changed["path"].connect (() => {
            queue_draw ();
        });
        
        settings.changed["position"].connect (() => {
            if (!ignore_reposition)
                reposition_from_settings ();
        });
        
        settings.changed["size"].connect (() => {
            if (!ignore_resize)
                resize_from_settings ();
        });

        draw.connect (on_draw);

        this.destroy.connect (Gtk.main_quit);
    }
    
    private void reposition_from_settings() {
        int left, top;
        settings.get("position", "(ii)", out left, out top);
        move(left, top);
    }
    
    private void resize_from_settings() {
        int width, height;
        settings.get("size", "(ii)", out width, out height);
        set_default_size (width, height);
    }
    
    private bool on_draw (Context ctx) {
        string path = settings.get_string ("path");

        int window_width, window_height;
        get_size (out window_width, out window_height);

        try {
            Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_scale (path, window_width, window_height, true);
            Gdk.cairo_set_source_pixbuf (ctx, pixbuf, 0, 0);

            int image_width = pixbuf.get_width();
            int image_height = pixbuf.get_height();
            if (window_width != image_width || window_height != image_height)
                resize(image_width, image_height);
        } catch (GLib.Error err) {
            stderr.printf("Error\n");
        }

        ctx.paint ();
        return true;
    }
}

int main (string[] args) {

    Gtk.init (ref args);
    
    // ensure we have a picture
    PicfSettings settings = new PicfSettings ();
    string path = settings.get_string ("path");
    try {
        new Gdk.Pixbuf.from_file (path);
    } catch (GLib.FileError err) {
        var file_chooser = new FileChooserDialog ("Choose Picture", null,
                                    FileChooserAction.OPEN,
                                    Stock.CANCEL, ResponseType.CANCEL,
                                    Stock.OPEN, ResponseType.ACCEPT);
        switch (file_chooser.run ()) {
        case ResponseType.ACCEPT:
            settings.set_string("path", file_chooser.get_filename ());
            break;
        case ResponseType.CANCEL:
            return -1;
        }
        file_chooser.destroy ();
    } catch (GLib.Error err) {
        return -2;
    }

    var float_window = new FloatWindow ();
    float_window.show_all ();

    Gtk.main ();

    return 0;
}











