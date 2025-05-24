# Organized imports
import time
import math
import gi
gi.require_version('GSound', '1.0')
gi.require_version('Notify', '0.7')
from gi.repository import (
    AstalIO, Astal, Gtk, Gdk, GSound, Notify, GLib, GObject,
    AstalBattery as Battery, AstalWp as Wp, AstalNetwork as Network,
    AstalTray as Tray, AstalMpris as Mpris, AstalHyprland as Hyprland,
)
from threading import Thread

Notify.init("Chrono App")

# ChronoStruct class to manage chrono state
class ChronoStruct:
    def __init__(self):
        self.is_running = True
        self.is_paused = True
        self.second = 0

    def toggle_pause(self):
        self.is_paused = not self.is_paused
        self.is_running = True

    def stop(self):
        self.is_running = False
        self.is_paused = True

    def set_timer_seconds(self, seconds):
        self.second = seconds

# Chrono main widget
class Chrono(Gtk.Box):
    def __init__(self, parent):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.set_halign(Gtk.Align.CENTER)
        self.set_valign(Gtk.Align.CENTER)
        self.set_margin_top(10)
        self.set_margin_bottom(10)
        self.set_margin_start(10)
        self.set_margin_end(10)

        self.notification = None
        self.time_state = ChronoStruct()

        self.time = ChronoInputContainers(self.time_state, parent)
        self.buttons = ChronoButtons(self.time_state)

        self.add(self.time)
        self.add(self.buttons)

        self.toggle_sound = True
        self.ctx = None

        self.time.connect("timer-finish", self.on_finish)
        self.buttons.connect("start", self.on_start)
        self.buttons.connect("stop", self.on_stop)

    def on_finish(self, widget):
        self.buttons.stop_timer(None) #to 'stop' after finish
        self.time.activate()
        self.send_notification("", "Timer Finish", "/home/alessio/github/dotfiles/apps/ags_test/icons/clock.png")
        GLib.timeout_add(1500, self.notification_sound)
        return 
    
    def notification_sound(self):
        if not self.toggle_sound:
            self.toggle_sound = True
            return False
        try:
            self.ctx = GSound.Context()
            self.ctx.init()
            self.ctx.play_simple({ GSound.ATTR_EVENT_ID: "suspend-error" })
        except Exception as e:
            print(f"ERROR: {e}")
            return False
        
        return True

    def on_start(self, button):
        self.time.start_timer()
    
    def on_stop(self, button):
        self.time.stop_timer()

    def send_notification(self, title, message, icon=None):
        if self.notification:
            self.notification.close()

        self.notification = Notify.Notification.new(title, message, icon)
        self.notification.set_urgency(2)
        self.notification.set_timeout(Notify.EXPIRES_NEVER)
        self.notification.add_action("stop", "Stop Timer", self.fallback, None)
        self.notification.set_app_name("Chrono App")

        # self.notification.add_action("posticipate", "Posticipate", self.fallback, None)
        self.notification.show()

    def fallback(self, notification, action, user_data):
        # if action == "stop":
        #     self.timer_state.stop()
        # elif action == "posticipate":
        #     self.countdown_seconds += self.posticipate_time
        self.toggle_sound = False

        self.notification.close()

# ChronoInputContainers for input fields
class ChronoInputContainers(Gtk.Box):
    __gsignals__ = {
        'timer-finish': (GObject.SIGNAL_RUN_FIRST, None, ())
    }
    def __init__(self, timer_state: ChronoStruct, parent):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        self.set_halign(Gtk.Align.CENTER)
        self.set_valign(Gtk.Align.CENTER)
        self.set_margin_top(10)
        self.set_margin_bottom(10)
        self.set_margin_start(10)
        self.set_margin_end(10)
        
        self.timer_state = timer_state
        self.total_seconds = 0

        self.seconds = ChronoInput(timer_state, self)
        self.minutes = ChronoInput(timer_state, self)
        self.hours = ChronoInput(timer_state, self)


        self.add(self.hours)
        self.add(Gtk.Label(":"))
        self.add(self.minutes)
        self.add(Gtk.Label(":"))
        self.add(self.seconds)

        # Connect custom signals
        self.seconds.connect("value-changed", self.on_value_changed)
        self.minutes.connect("value-changed", self.on_value_changed)
        self.hours.connect("value-changed", self.on_value_changed)

    def deactivate(self):
        self.seconds.set_sensitive(False)
        self.minutes.set_sensitive(False)
        self.hours.set_sensitive(False)
    
    def activate(self):
        self.seconds.set_sensitive(True)
        self.minutes.set_sensitive(True)
        self.hours.set_sensitive(True)

    def on_value_changed(self, widget):
        self.total_seconds = self.seconds.get_value() + self.minutes.get_value() * 60 + self.hours.get_value() * 3600
        self.timer_state.second = self.total_seconds
        # print(f"Total seconds: {self.total_seconds }")

    def get_value(self):
        total = 0
        total += self.seconds.get_value()
        total += self.minutes.get_value()*60
        total += self.hours.get_value()*3600
        self.total_seconds = total
        return total

    def start_timer(self):
        if(not self.total_seconds > 0 or self.timer_state.is_paused):
            self.activate()
            return
        self.deactivate()
        GLib.timeout_add(1000, self.timer)
        return

    def stop_timer(self):
        self.seconds.set_value_from_int(0)
        self.minutes.set_value_from_int(0)
        self.hours.set_value_from_int(0)
        return
    
    def timer(self):
        if(self.total_seconds <= 0 or self.timer_state.is_paused):
            if(self.total_seconds == 0):
                self.emit("timer-finish")
            return False
        self.total_seconds -= 1
        hours = int(self.total_seconds / 3600)
        minutes = int((self.total_seconds / 60) % 60)
        seconds = int(self.total_seconds % 60)
        self.seconds.set_value_from_int(seconds)
        self.minutes.set_value_from_int(minutes)
        self.hours.set_value_from_int(hours)
        self.on_value_changed(None)
        return True

# ChronoInput for individual time fields
class ChronoInput(Gtk.Button):
    __gsignals__ = {
        'value-changed': (GObject.SIGNAL_RUN_FIRST, None, ())
    }

    def __init__(self, timer_state: ChronoStruct, parent):
        super().__init__()
        self.set_halign(Gtk.Align.CENTER)
        self.set_margin_top(10)
        self.set_margin_bottom(10)
        self.set_margin_start(0)
        self.set_margin_end(0)

        self.posticipate_time = 5*60 # total seconds
        self.countdown_seconds = 0

        self.value = 0
        self.set_label(str(self.value))
        
        self.min = 0
        self.max = 60
        self.increment = 1
        # self.set_sensitive(False)
        self.set_size_request(60,20)
        self.parent = parent
        # self.adj = Gtk.Adjustment(0, 0, 59, 1)
        # self.set_adjustment(self.adj)
        # self.set_wrap(True)

        Astal.widget_set_css(self, "font-size: 22; font-weight: bold")
    
        self.connect("enter-notify-event", self.on_mouse_enter)
        self.connect("leave-notify-event", self.on_mouse_exit)
        self.connect("clicked", self.on_click)

    def on_click(self, widget):
        self.value = 0
        self.set_value()
            
        self.emit("value-changed")

    def increment_value(self, power=1, amoun=None):
        if amoun != None:
            self.value += amoun
        else:
            self.value += self.increment*power
        self.set_value()

    def set_value(self):
        self.emit("value-changed")
        self.set_label(str(math.ceil(self.value) % self.max))

    def set_value_from_int(self, value):
        self.set_label(str(value))
        self.emit("value-changed")

    def get_value(self):
        return int(self.get_label())
    
    def on_scroll(self, widget, event):
        if (not self.is_focus()):
            return
        self.increment_value(event.delta_y)
    
    def on_mouse_enter(self, widget, event):
        self.grab_focus()   

    def on_mouse_exit(self, widget, event):
        self.parent.grab_focus()

# ChronoButtons for Start/Stop buttons
class ChronoButtons(Gtk.Box):
    __gsignals__ = {
        'start': (GObject.SIGNAL_RUN_FIRST, None, ()),
        'stop': (GObject.SIGNAL_RUN_FIRST, None, ())
    }
    def __init__(self, timer_state: ChronoStruct):
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
        if(self.timer_state.second == 0):
            return
        self.timer_state.toggle_pause()
        self.button_start.set_label("" if self.timer_state.is_paused else "")
        self.emit("start")

    def stop_timer(self, widget):
        self.timer_state.stop()
        self.button_start.set_label("")
        self.emit("stop")
