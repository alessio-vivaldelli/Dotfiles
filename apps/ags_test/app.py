#!/usr/bin/env python3
# Organized imports
import json
import sys
import versions
import subprocess
from gi.repository import AstalIO, Astal, Gio, Gtk, Gdk, GLib, GObject
from widget.Bar import Bar
from pathlib import Path
from widget.TimerWidget import TimerApp
from widget.background import BackLayer

scss = str(Path(__file__).parent.resolve() / "style.scss")
css = "/tmp/style.css"
hide = False
tim = None

# App class for main application
class App(Astal.Application):
    def do_astal_application_request(self, msg: str, conn: Gio.SocketConnection) -> None:
        if msg == "toggle":
            is_hide = True
            win = []
            for window in self.get_windows():
                if window.is_visible():
                    window.hide()
                else:
                    is_hide = False
                    if "Back" in str(window):
                        win.insert(0, window)
                    else:
                        win.append(window)
                AstalIO.write_sock(conn, "hello")
            if not is_hide:
                for i in win:
                    i.show_all()
        elif msg == "info":
            test_info = {
                "text": " 󰔛 ",
                "alt": "1.0.0",
                "tooltop": "Test information"
            }
            AstalIO.write_sock(conn, json.dumps(test_info))

    def do_activate(self) -> None:
        self.hold()
        subprocess.run(["sass", scss, css])
        self.apply_css(css, True)

        mon = self.get_monitors()[0]
        back = BackLayer(mon)
        tim = TimerApp(mon)

        self.add_window(tim)
        self.add_window(back)
        back.set_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK)

        tim.connect("key-press-event", lambda w, e: self.hide_window() if e.keyval == Gdk.KEY_Escape else print("event"))
        tim.connect("focus-out-event", lambda w, e: print("OUT"))
        back.connect("button-press-event", lambda w, e: self.hide_window() if self.is_outside(tim.get_size(), e.x, e.y) else None)

    def is_outside(self, size, mouse_x, mouse_y):
        print("CHECK")
        if(mouse_x > size[0]*1.1 or mouse_y > size[1]*1.1):
            return True

    def hide_window(self):
        for window in self.get_windows():
            if window.is_visible():
                window.hide()
            else:
                window.show_all()

instance_name = "python"
app = App(instance_name=instance_name)

if __name__ == "__main__":
    try:
        app.acquire_socket()
        app.run(None)
    except Exception as e:
        print(AstalIO.send_message(instance_name, "".join(sys.argv[1:])))