An AutoHotKey GUI for working with todo.txt files.

To use this, you need to be running Windows with AutoHotKey installed. Just
double-click todo.ahk to start the script. You should see a green checkmark in
your system tray which tells you that it's running.

By default, it expects the todo.txt file to be in the same folder as the
script. You can change this by reading todo.ini.example and following its
instructions.

The hotkey is Win+T. If you want to change this, you have to edit and reload
the script.

Hit the hotkey and the GUI will appear. Your focus will be in the text box that
lets you add new items. Type in your item and hit ENTER to save it. The GUI
will disappear.

The GUI contains combo boxes for contexts and projects. You can select existing
contexts or projects or type in new ones. Whatever appears in the context and
project combo boxes will be added with your item (unless it's one of the
special entries like "(All)" or "(None)").

Don't put @ or + in front of what you type into the combo boxes--those get
added automatically to new items when you add them.

The context and project combo boxes remember what was last in them so
repeatedly hitting the hotkey to add new items lets you quickly add them to the
same context and project.

The context and project combo boxes also filter the list of visible items.
"(All)" shows all items. "(None)" shows items without a context or project.

You can check and uncheck items in the list. This marks them as done or not in
the todo.txt file.

You can also right-click items in the list. This allows you to update their
descriptions or delete them.

You can click the Archive button to move the checked items to a done.txt file.

Please enter any issues you find here:
https://github.com/jdiamond/todo.txt-ahk/issues.

The checkmark icon came from here:
http://www.iconspedia.com/icon/checkmark-12-20.html. I don't know why the file
is so huge for such a small icon.

