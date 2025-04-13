import time
import math
from gi.repository import (
    AstalIO,
    Astal,
    Gtk,
    Gdk,
    GLib,
    GObject,
    AstalBattery as Battery,
    AstalWp as Wp,
    AstalNetwork as Network,
    AstalTray as Tray,
    AstalMpris as Mpris,
    AstalHyprland as Hyprland,
)
from threading import Thread
from widget.ChronoWidget import *

class TimerCircular(Astal.CircularProgress):
    def __init__(self, timer_state):
        super().__init__()
        self.val = 0.0
        self.set_rounded(True)

        margin = 20
        self.set_margin_top(margin)
        self.set_margin_bottom(10)
        self.set_margin_start(margin)
        self.set_margin_end(margin)
        self.set_size_request(150, 150)
        self.set_start_at(-0.250)
        self.set_end_at(-0.250)

        self.timer_state = timer_state
        self.mutex = True
        self.gain = 0.000166666

class BackLayer(Astal.Window):
    def __init__(self, monitor: Gdk.Monitor):
        super().__init__(
            anchor=Astal.WindowAnchor.LEFT
            | Astal.WindowAnchor.RIGHT
            | Astal.WindowAnchor.TOP
            | Astal.WindowAnchor.BOTTOM,
            gdkmonitor=monitor,
            margin_top=30,
            margin_bottom=0,
            exclusivity=Astal.Exclusivity.IGNORE,
            # keymode=Astal.Keymode.EXCLUSIVE,
        )

        # Astal.widget_set_class_names(self, ["Timer"])
        self.set_title("Timer")
        Astal.widget_set_css(self, "background-color: rgba(76, 175, 80, 0.0);")

        # # Rimuove i bordi della finestra e rende la finestra invisibile
        # self.set_decorated(False)
        # self.set_resizable(False)
        # self.set_type_hint(Gdk.WindowTypeHint.UTILITY)

        # # Impostiamo la finestra come modale
        # self.set_modal(True)
        # self.set_focus_on_map(True)
        # # Impediamo che la finestra prenda il focus per impostazione predefinita
        # self.set_accept_focus(True)  # Assicurati che la finestra accetti il focus

        # super().__init__()
        self.connect("destroy", self.on_close)
        # self.set_default_size(300, 400)
        # self.set_size_request(150, 150)

        # self.set_decorated(False)
        # self.set_transient_for(None)
        # self.set_type_hint(Gdk.WindowTypeHint.UTILITY) # UTILITY
        # self.move(0, 0)
        # self.set_resizable(False)

        box = Astal.Box()
        self.add(box)
        self.show_all()



    def on_close(self, *args):
        Gtk.main_quit()
        exit(0)

