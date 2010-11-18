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
CONTEXT_LABEL := "Context:"
ITEMS_LABEL := "Items:"

NONE_TEXT := "(None)"
ALL_TEXT := "(All)"

CHECK_COLUMN := 1
TEXT_COLUMN := 2
CONTEXT_COLUMN := 3
PROJECT_COLUMN := 4

CHECK_HEADER := ""
TEXT_HEADER := "Description"
CONTEXT_HEADER := "Context"
PROJECT_HEADER := "Project"
LINE_NUMBER_HEADER := "Line #"

OK_BUTTON_TEXT := "OK"

CONTROL_WIDTH := 400

DELETE_PROMPT := "Are you sure you want to delete ""`%text`%""?"

; Set our icon.
Menu TRAY, Icon, %ICON_PATH%

; Define the GUI.
Gui +Resize
Gui Add, Text,, %ADD_LABEL%
Gui Add, Text,, %CONTEXT_LABEL%
Gui Add, Text,, %PROJECT_LABEL%
Gui Add, Text,, %ITEMS_LABEL%
Gui Add, Edit, vNewItem ym W%CONTROL_WIDTH%
Gui Add, ComboBox, vContext gContext W%CONTROL_WIDTH% Sort, %ALL_TEXT%||%NONE_TEXT%
Gui Add, ComboBox, vProject gProject W%CONTROL_WIDTH% Sort, %ALL_TEXT%||%NONE_TEXT%
Gui Add, ListView, vItems gItems Checked W%CONTROL_WIDTH%, %CHECK_HEADER%|%TEXT_HEADER%|%CONTEXT_HEADER%|%PROJECT_HEADER%|%LINE_NUMBER_HEADER%
Gui Add, Button, default, %OK_BUTTON_TEXT%

; Define the context menu.
Menu ItemMenu, Add, Update, MenuHandler
Menu ItemMenu, Add, Delete, MenuHandler

Return

; Win+T is the default hotkey.
#t::
Gui Show,, %WINDOW_TITLE%
GuiControl Focus, NewItem
GuiControlGet Context
GuiControlGet Project
ReadFile(Context, Project, true)
Return

; Handle when the OK button is clicked or the ENTER key is pressed.
ButtonOK:
Gui Submit
AddItem(NewItem, Context, Project)
GuiControl ,, NewItem,
Return

; Handle when the context combo box changes.
Context:
FilterItems()
Return

; Handle when the project combo box changes.
Project:
FilterItems()
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
  DeleteItem(selectedRow)
Return

; Handle when the X is clicked or when the ESCAPE key is pressed.
GuiClose:
GuiEscape:
Gui Cancel
Return

; Handle when the GUI is resized so we can resize its controls.
GuiSize:
Anchor("NewItem", "w")
Anchor("Context", "w")
Anchor("Project", "w")
Anchor("Items", "wh")
Anchor("OK", "y")
Return

; Filters the items displayed in the list view.
FilterItems() {
  GuiControlGet Context
  GuiControlGet Project
  ReadFile(Context, Project, false)
}

; Read the todo.txt file into the GUI.
; Does filtering based on the context and project parameters passed in.
ReadFile(context, project, refreshCombos) {
  Global TODO_PATH
  Global NONE_TEXT
  Global ALL_TEXT

  ; Disable notifications for checking and unchecking while the list is populated.
  GuiControl, -AltSubmit, Items

  lineNumber := 0

  If (refreshCombos) {
    ; Clear the combo boxes.
    GuiControl ,, Context, ||
    GuiControl ,, Project, ||
    ; Use these variables to keep track of what contexts and projects have been added.
    contextsAdded := "|"
    projectsAdded := "|"
  }

  ; Clear the list view.
  LV_Delete()

  Loop Read, %TODO_PATH%
  {
    lineNumber := lineNumber + 1

    line := TrimWhitespace(A_LoopReadLine)

    If (line <> "") {
      ParseLine(line, donePart, textPart, contextPart, projectPart)

      If (refreshCombos And contextPart <> "") {
        If (InStr(contextsAdded, "|" . contextPart . "|") = 0) {
          GuiControl ,, Context, %contextPart%
          contextsAdded := contextsAdded . contextPart . "|"
        }
      }

      If (refreshCombos And projectPart <> "") {
        If (InStr(projectsAdded, "|" . projectPart . "|") = 0) {
          GuiControl ,, Project, %projectPart%
          projectsAdded := projectsAdded . projectPart . "|"
        }
      }

      If (Matches(contextPart, context) And Matches(projectPart, project)) {
        AddItemToList(donePart, textPart, contextPart, projectPart, lineNumber)
      }
    }
  }

  If (refreshCombos) {
    ; Modify all columns to auto-fit their content.
    LV_ModifyCol()

    ; Add the All and None options.
    GuiControl ,, Context, %ALL_TEXT%|%NONE_TEXT%
    GuiControl ,, Project, %ALL_TEXT%|%NONE_TEXT%

    ; Re-select the values that were previously selected.
    GuiControl ChooseString, Context, %context%
    GuiControl ChooseString, Project, %project%
  }

  ; Re-enable notifications for handling checking and unchecking.
  GuiControl, +AltSubmit, Items
}

; Check if the actual value matches the expected value.
; Handles when expected is "(None)" or "(All)".
Matches(actual, expected) {
  Global NONE_TEXT
  Global ALL_TEXT

  If (expected = NONE_TEXT) {
    If (actual <> "") {
      Return false
    }
  } Else If (expected <> ALL_TEXT) {
    If (RegExMatch(actual, "^" . expected) = 0) {
      Return false
    }
  }

  Return true
}

; Add an item to the list view.
AddItemToList(donePart, textPart, contextPart, projectPart, lineNumber) {
  If (donePart <> "") {
    LV_Insert(1, "Check", "", textPart, contextPart, projectPart, lineNumber)
  } Else {
    LV_Insert(1, "", "", textPart, contextPart, projectPart, lineNumber)
  }
}

; Add an item to todo.txt.
AddItem(newItem, context, project) {
  Global TODO_PATH

  newItem := TrimWhitespace(newItem)
  context := TrimWhitespace(context)
  project := TrimWhitespace(project)

  If (newItem <> "") {
    line := MakeLine("", newItem, context, project)
    FileAppend %line%`n, %TODO_PATH%
  }
}

; Check or uncheck an item in todo.txt.
CheckItem(rowNumber, checked) {
  Global TEXT_COLUMN
  Global CONTEXT_COLUMN
  Global PROJECT_COLUMN

  LV_GetText(text, rowNumber, TEXT_COLUMN)
  LV_GetText(context, rowNumber, CONTEXT_COLUMN)
  LV_GetText(project, rowNumber, PROJECT_COLUMN)

  UpdateFile("CheckItemAction", checked, text, context, project)
}

CheckItemAction(checked, ByRef donePart, ByRef textPart, ByRef contextPart, ByRef projectPart) {
  If (checked) {
    If (donePart = "")
      donePart := "x " . A_YYYY . "-" . A_MM . "-" . A_DD
  } Else {
    donePart := ""
  }
}

DeleteItem(rowNumber) {
  Global TEXT_COLUMN
  Global CONTEXT_COLUMN
  Global PROJECT_COLUMN
  Global DELETE_PROMPT

  LV_GetText(text, rowNumber, TEXT_COLUMN)
  LV_GetText(context, rowNumber, CONTEXT_COLUMN)
  LV_GetText(project, rowNumber, PROJECT_COLUMN)

  StringReplace prompt, DELETE_PROMPT, `%text`%, %text%
  MsgBox 4,, %prompt%

  IfMsgBox No
    Return

  UpdateFile("DeleteItemAction", 0, text, context, project)

  FilterItems()
}

DeleteItemAction(data, ByRef donePart, ByRef textPart, ByRef contextPart, ByRef projectPart) {
  donePart := ""
  textPart := ""
  contextPart := ""
  projectPart := ""
}

; Generic function for updating items in todo.txt.
; `action` is name of function to invoke for matching items.
; Function must have this signature:
;   MyAction(data, ByRef donePart, ByRef textPart, ByRef contextPart, ByRef projectPart)
; `data` is any value that `action` might need.
UpdateFile(action, data, text, context, project) {
  Global TODO_PATH
  Global TODO_FILE_NAME

  tempPath := A_Temp . "\" . TODO_FILE_NAME . ".tmp"

  FileDelete tempPath

  Loop Read, %TODO_PATH%
  {
    line := TrimWhitespace(A_LoopReadLine)

    If (line = "") {
        FileAppend `n, %tempPath%
    } Else {
      ParseLine(line, donePart, textPart, contextPart, projectPart)

      If (textPart = text And contextPart = context And projectPart = project) {
        %action%(data, donePart, textPart, contextPart, projectPart)
      }

      line := MakeLine(donePart, textPart, contextPart, projectPart)

      FileAppend %line%`n, %tempPath%
    }
  }

  FileMove %tempPath%, %TODO_PATH%, 1
  FileDelete tempPath
}

; Parse a line from todo.txt.
ParseLine(line, ByRef donePart, ByRef textPart, ByRef contextPart, ByRef projectPart) {
  RegExMatch(line, "^(x \d\d\d\d-\d\d-\d\d\s+)?(.+?)(@\w[^+]*)?(\+\w.*)?$", lineParts)
  donePart := TrimWhitespace(lineParts1)
  textPart := TrimWhitespace(lineParts2)
  contextPart := TrimWhitespace(RegExReplace(lineParts3, "^@"))
  projectPart := TrimWhitespace(RegExReplace(lineParts4, "^\+"))
}

; Put a parsed line back together for writing to todo.txt.
MakeLine(donePart, textPart, contextPart, projectPart) {
  Global NONE_TEXT
  Global ALL_TEXT

  line := textPart
  If (donePart <> "") {
    line := donePart . " " . line
  }
  If ((contextPart <> "") And (contextPart <> NONE_TEXT) And (contextPart <> ALL_TEXT)) {
    line := line . " @" . contextPart
  }
  If ((projectPart <> "") And (projectPart <> NONE_TEXT) And (projectPart <> ALL_TEXT)) {
    line := line . " +" . projectPart
  }
  Return line
}

; Remove whitespace from the beginning and end of the string.
TrimWhitespace(str) {
  Return RegExReplace(str, "(^\s+)|(\s+$)")
}

