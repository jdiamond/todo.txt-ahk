#Include Anchor.ahk

TODO_FILE_NAME := "todo.txt"
DONE_FILE_NAME := "done.txt"
ICON_FILE_NAME := "todo.ico"

TODO_PATH := A_ScriptDir . "\" . TODO_FILE_NAME
DONE_PATH := A_ScriptDir . "\" . DONE_FILE_NAME
ICON_PATH := A_ScriptDir . "\" . ICON_FILE_NAME

WINDOW_TITLE := "TODOs"

ADD_LABEL := "Add:"
PROJECT_LABEL := "Project:"
ITEMS_LABEL := "Items:"

ALL_PROJECTS := "(All)"
NO_PROJECTS := "(None)"

CHECK_COLUMN := 1
TEXT_COLUMN := 2
PROJECT_COLUMN := 3

CHECK_HEADER := ""
TEXT_HEADER := "Description"
PROJECT_HEADER := "Project"

OK_BUTTON_TEXT := "OK"

CONTROL_WIDTH := 400

; Set our icon.
Menu TRAY, Icon, %ICON_PATH%

; Define the GUI.
Gui +Resize
Gui Add, Text,, %ADD_LABEL%
Gui Add, Text,, %PROJECT_LABEL%
Gui Add, Text,, %ITEMS_LABEL%
Gui Add, Edit, vNewItem ym W%CONTROL_WIDTH%
Gui Add, ComboBox, vProject gProject W%CONTROL_WIDTH% Sort, %ALL_PROJECTS%||%NO_PROJECTS%
Gui Add, ListView, vItems gItems Checked AltSubmit W%CONTROL_WIDTH%, %CHECK_HEADER%|%TEXT_HEADER%|%PROJECT_HEADER%
Gui Add, Button, default, %OK_BUTTON_TEXT%

; Define the context menu.
Menu ItemMenu, Add, Update, MenuHandler
Menu ItemMenu, Add, Delete, MenuHandler

Return

; Win+T is the default hotkey.
#t::
Gui Show,, %WINDOW_TITLE%
GuiControl Focus, NewItem
GuiControlGet Project
ReadFile(Project, true)
Return

; Handle when the OK button is clicked or the ENTER key is pressed.
ButtonOK:
Gui Submit
AddItem(NewItem, Project)
GuiControl ,, NewItem,
Return

; Handle when the project combo box changes.
Project:
GuiControlGet Project
ReadFile(Project, false)
Return

; Handle when an item is checked or unchecked.
Items:
If (A_GuiEvent = "I") {
  If (InStr(ErrorLevel, "C", true))
    CheckItem(A_EventInfo, true)
  Else If (InStr(ErrorLevel, "c", true))
    CheckItem(A_EventInfo, false)
}
Return

; Handle when an item is right-clicked.
GuiContextMenu:
If (A_GuiControl = "Items")
  Menu ItemMenu, Show
Return

; Handle when an item is selected in the context menu.
MenuHandler:
selectedRow := LV_GetNext()
If (A_ThisMenuItem = "Update")
  MsgBox You want to UPDATE row %selectedRow%!
Else If (A_ThisMenuItem = "Delete")
  MsgBox You want to DELETE row %selectedRow%!
Return

; Handle when the X is clicked or when the ESCAPE key is pressed.
GuiClose:
GuiEscape:
Gui Cancel
Return

; Handle when the GUI is resized so we can resize its controls.
GuiSize:
Anchor("NewItem", "w")
Anchor("Project", "w")
Anchor("Items", "wh")
Anchor("OK", "y")
Return

; Read the todo.txt file into the GUI.
ReadFile(project, refreshProjects) {
  Global TODO_PATH
  Global ALL_PROJECTS
  Global NO_PROJECTS

  If (refreshProjects) {
    ; Clear the combo box.
    GuiControl ,, Project, ||
    ; Use this variable to keep track of what projects have been added.
    projectsAdded := ""
  }

  ; Clear the list view.
  LV_Delete()

  Loop Read, %TODO_PATH%
  {
    line := TrimWhitespace(A_LoopReadLine)

    If (line <> "") {
      ParseLine(line, donePart, textPart, projectPart)

      If (refreshProjects And projectPart <> "") {
        If (InStr(projectsAdded, projectPart . "|") = 0) {
          GuiControl ,, Project, %projectPart%
          projectsAdded := projectsAdded . projectPart . "|"
        }
      }

      If (project = NO_PROJECTS) {
        If (projectPart = "") {
          AddItemToList(donePart, textPart, projectPart)
        }
      } Else If (project = ALL_PROJECTS) {
        AddItemToList(donePart, textPart, projectPart)
      } Else {
        If (RegExMatch(projectPart, "^" . project) > 0) {
          AddItemToList(donePart, textPart, projectPart)
        }
      }
    }
  }

  ; Modify all columns to auto-fit their content.
  LV_ModifyCol()

  If (refreshProjects) {
    ; Add the All and None options.
    GuiControl ,, Project, %ALL_PROJECTS%|%NO_PROJECTS%
    ; Re-select the project that was previously selected.
    GuiControl ChooseString, Project, %project%
  }
}

; Add an item to the list view.
AddItemToList(donePart, textPart, projectPart) {
  Global CHECK_COLUMN
  If (donePart <> "")
    LV_Insert(CHECK_COLUMN, "Check", "", textPart, projectPart)
  Else
    LV_Insert(CHECK_COLUMN, "", "", textPart, projectPart)
}

; Add an item to todo.txt.
AddItem(newItem, project) {
  Global TODO_PATH
  Global ALL_PROJECTS
  Global NO_PROJECTS

  newItem := TrimWhitespace(newItem)
  project := TrimWhitespace(project)

  If (newItem <> "") {
    If (project = ALL_PROJECTS Or project = NO_PROJECTS Or project = "")
      FileAppend %newItem%`n, %TODO_PATH%
    Else
      FileAppend %newItem% +%project%`n, %TODO_PATH%
  }
}

; Check or uncheck an item in todo.txt.
CheckItem(rowNumber, checked) {
  Global TODO_PATH
  Global TODO_FILE_NAME
  Global TEXT_COLUMN
  Global PROJECT_COLUMN

  LV_GetText(text, rowNumber, TEXT_COLUMN)
  LV_GetText(project, rowNumber, PROJECT_COLUMN)

  tempPath := A_Temp . "\" . TODO_FILE_NAME . ".tmp"

  FileDelete tempPath

  Loop Read, %TODO_PATH%
  {
    line := TrimWhitespace(A_LoopReadLine)

    If (line = "") {
        FileAppend `n, %tempPath%
    } Else {
      ParseLine(line, donePart, textPart, projectPart)

      If (textPart = text And projectPart = project) {
        If (checked)
          donePart := "x " . A_YYYY . "-" . A_MM . "-" . A_DD
        Else
          donePart := ""
      }

      line := MakeLine(donePart, textPart, projectPart)

      FileAppend %line%`n, %tempPath%
    }
  }

  FileMove %tempPath%, %TODO_PATH%, 1
  FileDelete tempPath
}

; Parse a line from todo.txt.
ParseLine(line, ByRef donePart, ByRef textPart, ByRef projectPart) {
  RegExMatch(line, "^(x \d\d\d\d-\d\d-\d\d\s+)?(.+?)(\+\S.+)?$", lineParts)
  donePart := TrimWhitespace(lineParts1)
  textPart := TrimWhitespace(lineParts2)
  projectPart := TrimWhitespace(RegExReplace(lineParts3, "^\+"))
}

; Put a parsed line back together for writing to todo.txt.
MakeLine(donePart, textPart, projectPart) {
  line := textPart
  If (donePart <> "") {
    line := donePart . " " . line
  }
  If (projectPart <> "") {
    line := line . " +" . projectPart
  }
  Return line
}

; Remove whitespace from the beginning and end of the string.
TrimWhitespace(str) {
  Return RegExReplace(str, "(^\s+)|(\s+$)")
}

