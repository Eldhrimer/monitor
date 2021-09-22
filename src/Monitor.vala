namespace Monitor {
    public class MonitorApp : Gtk.Application {
        public static Settings settings;
        private MainWindow window = null;
        public string[] args;

        private static bool start_in_background = false;
        private static bool status_background = false;
        private const GLib.OptionEntry[] CMD_OPTIONS = {
            // --start-in-background
            { "start-in-background", 'b', 0, OptionArg.NONE, ref start_in_background, "Start in background with wingpanel indicator", null },
            // list terminator
            { null }
        };

        // contructor replacement, flags added
        public MonitorApp (bool status_indicator) {
            Object (
                application_id: "com.github.stsdc.monitor",
                flags : ApplicationFlags.FLAGS_NONE
                );
            status_background = status_indicator;
        }

        static construct {
            settings = new Settings ("com.github.stsdc.monitor.settings");
        }

        public override void activate () {
            // only have one window
            if (get_windows () != null) {
                window.show_all ();
                window.present ();
                return;
            }

            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();

            bool is_dark = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
            gtk_settings.gtk_application_prefer_dark_theme = is_dark;


            var provider = new Gtk.CssProvider ();

            if (is_dark) {
                provider.load_from_resource ("/com/github/stsdc/monitor/dark.css");
            } else {
                provider.load_from_resource ("/com/github/stsdc/monitor/light.css");
            }

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                
            // We listen to changes in Granite.Settings and update our app if the user changes their preference
            granite_settings.notify["prefers-color-scheme"].connect (() => {
                is_dark = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                gtk_settings.gtk_application_prefer_dark_theme = is_dark;
                
                if (is_dark) {
                    provider.load_from_resource ("/com/github/stsdc/monitor/dark.css");
                } else {
                    provider.load_from_resource ("/com/github/stsdc/monitor/light.css");
                }
            });

            

            window = new MainWindow (this);

            // start in background with indicator
            if (status_background || MonitorApp.settings.get_boolean ("background-state")) {
                if (!MonitorApp.settings.get_boolean ("indicator-state")) {
                    MonitorApp.settings.set_boolean ("indicator-state", true);
                }
                if (!MonitorApp.settings.get_boolean ("indicator-cpu-state")) {
                    MonitorApp.settings.set_boolean ("indicator-cpu-state", true);
                }
                if (!MonitorApp.settings.get_boolean ("indicator-memory-state")) {
                    MonitorApp.settings.set_boolean ("indicator-memory-state", true);
                }
                if (!MonitorApp.settings.get_boolean ("indicator-temperature-state")) {
                    MonitorApp.settings.set_boolean ("indicator-temperature-state", true);
                }
                if (!MonitorApp.settings.get_boolean ("indicator-network-up-state")) {
                    MonitorApp.settings.set_boolean ("indicator-network-up-state", false);
                }
                if (!MonitorApp.settings.get_boolean ("indicator-network-down-state")) {
                    MonitorApp.settings.set_boolean ("indicator-network-down-state", false);
                }

                window.hide ();
                MonitorApp.settings.set_boolean ("background-state", true);
            } else {
                window.show_all ();
            }

            window.process_view.process_tree_view.focus_on_first_row ();

            var quit_action = new SimpleAction ("quit", null);
            add_action (quit_action);
            set_accels_for_action ("app.quit", { "<Ctrl>q" });
            quit_action.activate.connect (() => {
                if (window != null) {
                    window.destroy ();
                }
            });


            // Controls the direction of the sort indicators
            Gtk.Settings.get_default ().set ("gtk-alternative-sort-arrows", true, null);
        }

        public static int main (string[] args) {
            // add command line options
            try {
                var opt_context = new OptionContext ("");
                opt_context.set_help_enabled (true);
                opt_context.add_main_entries (CMD_OPTIONS, null);
                opt_context.parse (ref args);
            } catch (OptionError e) {
                print ("Error: %s\n", e.message);
                print ("Run '%s --help' to see a full list of available command line options.\n\n", args[0]);
                return 0;
            }

            var app = new MonitorApp (start_in_background);

            return app.run (args);
        }

    }
}
