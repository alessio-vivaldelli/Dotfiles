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

class TimerState:
    def __init__(self):
        self.is_running = True
        self.is_paused = True

    def toggle_pause(self):
        self.is_paused = not self.is_paused
        self.is_running = True

    def stop(self):
        self.is_running = False
        self.is_paused = True

class TimerButtons(Gtk.Box):
    def __init__(self, timer_state):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        Astal.widget_set_class_names(self, ["TimerButtons"])
        self.set_halign(Gtk.Align.CENTER)
        self.set_margin_top(10)
        self.set_margin_bottom(10)
        self.set_margin_start(10)
        self.set_margin_end(10)

        self.timer_state = timer_state

        self.button_start = Gtk.Button(label="")
        self.button_start.connect("clicked", self.start_timer)
        self.button_stop = Gtk.Button(label="")
        self.button_stop.connect("clicked", self.stop_timer)

        Astal.widget_set_css(self.button_stop, "color: #f38ba8")
        Astal.widget_set_css(self.button_start, "color: #a6e3a1;min-width: 75px;margin-right: -5px;")

        self.button_start.set_margin_right(5)
        self.add(self.button_start)
        self.add(self.button_stop)

    def start_timer(self, widget):
        self.timer_state.toggle_pause()
        self.button_start.set_label("" if self.timer_state.is_paused else "")

    def stop_timer(self, widget):
        self.timer_state.stop()
        self.button_start.set_label("")

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

        GLib.timeout_add(100, self.check_is_running)

    def check_is_running(self):
        if self.timer_state.is_running and self.mutex:
            self.start_animation()
            self.mutex = False
        if not self.timer_state.is_running:
            self.val = 0.0
            self.set_value(self.val)
        return True

    def start_animation(self):
        GLib.timeout_add(10, self.update_progress)

    def update_progress(self):
        if self.timer_state.is_paused or not self.timer_state.is_running:
            return True
        self.set_value(self.val)
        self.val = (self.val + self.gain) % 1.0
        return True

class OverlayBox(Gtk.Box):
    def __init__(self, timer_state):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.label = Gtk.Label()
        self.label.set_markup("<span font='20'><b>00:00</b></span>")
        self.add(self.label)
        self.gain = 1
        self.total = 0
        self.timer_state = timer_state

        GLib.timeout_add(1000, self.update_timer)

    def update_timer(self):
        if not self.timer_state.is_running:
            self.label.set_label("<span font='20'><b>00:00</b></span>")
            self.total = 0
        if not self.timer_state.is_paused:
            self.total += self.gain

        if self.total < 3600:
            self.label.set_label("<span font='20'><b>{:02d}:{:02d}</b></span>".format(int(self.total / 60), int(self.total % 60)))
        else:
            self.label.set_label("<span font='12'><b>{:02d}:{:02d}:{:02d}</b></span>".format(int(self.total / 3600), int((self.total / 60) % 60), int(self.total % 60)))

        return True

class TimerCircularOverlay(Gtk.Overlay):
    def __init__(self, timer_state):
        super().__init__()
        self.circular = TimerCircular(timer_state)
        self.add(self.circular)
        self.overlay_box = OverlayBox(timer_state)
        self.overlay_box.set_halign(Gtk.Align.CENTER)
        self.overlay_box.set_valign(Gtk.Align.CENTER)
        self.add_overlay(self.overlay_box)


class TimerContainer(Gtk.Box):
    def __init__(self, timer_state):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.set_spacing(10)
        self.timer_buttons = TimerButtons(timer_state)
        self.timer_circular = TimerCircularOverlay(timer_state)
        self.add(self.timer_circular)
        self.add(self.timer_buttons)

class Header(Gtk.Box):
    def __init__(self, stack):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.set_halign(Gtk.Align.CENTER)
        self.set_margin_top(10)
        self.set_margin_bottom(10)
        self.set_margin_start(10)
        self.set_margin_end(10)

        self.stack_switcher = Gtk.StackSwitcher()
        self.stack_switcher.set_stack(stack)
        self.add(self.stack_switcher)




class TimerApp(Gtk.Window):
    def __init__(self, monitor: Gdk.Monitor):
        super().__init__()
        self.connect("destroy", self.on_close)
        self.set_title("Timer")
        # self.set_default_size(300, 400)
        self.set_decorated(False)
        self.set_transient_for(None)
        self.set_type_hint(Gdk.WindowTypeHint.UTILITY) # UTILITY
        self.move(0, 0)
        self.set_resizable(False)

        timer_state = TimerState()

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(250)
        Astal.widget_set_css(self.stack, "font-size: 20; font-weight: bold")

        timer_container = TimerContainer(timer_state)
        # Placeholder for another widget (e.g., Timer)
        self.chrono_widget = Chrono(self)
        self.chrono_widget.add_events(Gdk.EventMask.SCROLL_MASK)
        self.stack.add_titled(timer_container, "timer", "󰔛")
        self.stack.add_titled(self.chrono_widget, "another", "󰚭")
        

        header = Header(self.stack)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        vbox.pack_start(header, False, False, 0)
        vbox.pack_start(self.stack, True, True, 0)

        self.add(vbox)
        self.show_all()


        self.connect("scroll-event", self.on_scroll)

    def on_scroll(self, widget, event):
        c = self.chrono_widget.time.get_children()
        for i in c:
            if isinstance(i, ChronoInput):
                i.on_scroll(widget, event)

    def on_close(self, *args):
        Gtk.main_quit()
        exit(0)

