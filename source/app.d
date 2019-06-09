import std.stdio : write, writeln, writefln;
import std.ascii;
import std.format;
import std.conv;
import std.string;
import core.stdc.stdio;
import core.sys.posix.termios;
import core.sys.posix.sys.ioctl;
import core.runtime;

import TextEditor;

extern (C) void cfmakeraw(in termios*);

termios ostate;
termios nstate;

struct EditorConfig {
  // Editor screen dimensions
  int screenrows;
  int screencols;
  // cx and cy represent cursor position in char array, rx in screen rendering.
  int cx, cy, rx;
  // These offsites define the scrolling offset of text
  int rowoff;
  int coloff;
  //This buffer contains all the characters to be rendered
  string screenbuffer;
}

EditorConfig configuration;
TextEditor editor;

// Control character constants
const short CONTROL_QUIT = 17;
const short CONTROL_R = 18;
const short CONTROL_ESC = 27;
//Editor state constants
const short EDITOR_QUIT = 1005;
const short EDITOR_CONTINUE = 1006;
// Keyboard constants
const short ARROW_UP = 1000;
const short ARROW_RIGHT = 1001;
const short ARROW_DOWN = 1002;
const short ARROW_LEFT = 1003;
const short PAGE_UP = 1004;
const short PAGE_DOWN = 1007;
const short DELETE = 1008;
const short HOME = 1009;
const short END = 1010;
const short INSERT = 1011;
const short ENTER = 1012;

const string EDITOR_VERSION = "0.1";
const int TAB_STOP = 8;

// These variables and functions are for debugging
string debugStr = "";
const DEBUG = 1;

string printDebug() {
  if(DEBUG == 1) {
    string ret = debugStr;
    debugStr = "";
    return ret;
  }
}

void mydebug(string str) {
  debugStr ~= str;
}

void enterRawMode() {
  tcgetattr(1, &ostate);
  tcgetattr(1, &nstate);
  // cfmakeraw(&nstate);
  nstate.c_iflag &= ~(IXON);
  nstate.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
  nstate.c_cc[VMIN] = 0;
  nstate.c_cc[VTIME] = 1;
  tcsetattr(1, TCSAFLUSH, &nstate);
}

void endRawMode() {
  tcsetattr(1, TCSADRAIN, &ostate); // return to original mode
}

void initEditor() {
  configuration.screenrows = 24;
  configuration.screencols = 80;
  configuration.screenbuffer = "";
  configuration.cx = 0;
  configuration.cy = 0;
  configuration.rx = 0;
  configuration.rowoff = 0;
  configuration.coloff = 0;

  // last line is status bar. Make space for it
  configuration.screenrows -= 1;
}

short processKeyPress() {
  int c = readKeyPress();

  switch(c) {
  case EDITOR_QUIT:
    return EDITOR_QUIT;
  case ARROW_UP:
  case ARROW_RIGHT:
  case ARROW_DOWN:
  case ARROW_LEFT:
  case HOME:
  case END:
  case PAGE_DOWN:
  case PAGE_UP:
    moveCursor(c);
    break;
  case ENTER:
    return EDITOR_CONTINUE;
  case EDITOR_CONTINUE:
    return EDITOR_CONTINUE;
  default:
      insertChar(cast(char) c);
  }
  return 0;
}

int readKeyPress(){
  int c;
  c = fgetc(stdin);

  if( c == -1) {
    return EDITOR_CONTINUE;
  }

  if(isControl(c)) {
      int[3] res;

    // The fgetc function returns -1 if no result
    res[0] = fgetc(stdin);
    res[1] = fgetc(stdin);
    // Debug:
    // writefln("%d %d %d", c, res[0], res[1]);

    if(cast(short) c == CONTROL_QUIT) {
      writeln("bye!");
      return EDITOR_QUIT;

    }

    if(res[0] == 9) {
      // tab
      return EDITOR_CONTINUE;
    }

    if(res[0] == 127) {
      //Backspace
      return EDITOR_CONTINUE;
    }

    if(res[0] == 91) {
      switch(res[1]) {
      case 72: return HOME;
      case 70: return END;
      case 53: return PAGE_UP;
      case 54: return PAGE_DOWN;
      case 65: return ARROW_UP;
      case 66: return ARROW_DOWN;
      case 67: return ARROW_RIGHT;
      case 68: return ARROW_LEFT;
        //delete:
      case 51:
      default: return EDITOR_CONTINUE;
      }
    }


  } else if( c == '\n' || c == '\r') {
    return ENTER;
  } else {
    return c;
  }
  return 0;
}

void moveCursor(int key) {
  final switch(key) {
  case HOME:
    configuration.cx = 0;
    break;
  case END:
    configuration.cx = editor.getLineLength(configuration.cy);
    break;
  case PAGE_DOWN:
    configuration.cy += configuration.screenrows;
    if(configuration.cy > editor.getLineAmount()) {
      configuration.cy = cast(int)editor.getLineAmount();
    }
    break;
  case PAGE_UP:
    configuration.cy -= configuration.screenrows;
    if(configuration.cy < 0) {
      configuration.cy = 0;
    }
    break;
  case ARROW_UP:
    if(configuration.cy > 0) {
      configuration.cy--;
    }
    break;
  case ARROW_RIGHT:
    if(configuration.cx < editor.getLineLength(configuration.cy)){
      configuration.cx++;
    } else if(configuration.cy < editor.getLineAmount) {
      configuration.cy++;
      configuration.cx = 0;
    }
    break;
  case ARROW_DOWN:
    if(configuration.cy < editor.getLineAmount()) {
      configuration.cy++;
    }
    break;
  case ARROW_LEFT:
    if(configuration.cx > 0) {
      configuration.cx--;
    } else if(configuration.cy > 0) {
      configuration.cy--;
      configuration.cx = editor.getLineLength(configuration.cy);
    }
    break;
  }

  if(configuration.cx > editor.getLineLength(configuration.cy)) {
    configuration.cx = editor.getLineLength(configuration.cy);
  }


}

void insertChar(char c) {
  editor.putChar(c, configuration.cy, configuration.cx);
  configuration.cx++;
}

void printchars(string str) {
  configuration.screenbuffer = format("%s%s", configuration.screenbuffer, str);
}

string centerStr(string str) {
  return center(str, configuration.screencols);
}

void clearScreen() {
  //empty whole screen
  printchars("\x1b[2J");
  //move cursor to upper left corner
  printchars("\x1b[H");

}

void updatescreen() {
  editorScroll();

  //move cursor to upper corner
  write("\x1b[?25l");

  drawRows();
  drawStatusBar();

  //Reposition the cursor on the top of the screen
  printchars("\x1b[H");

  // print cursor
  printchars(format("\x1b[%d;%dH", (configuration.cy - configuration.rowoff) + 1,
                    (configuration.rx - configuration.coloff) + 1));

  write(configuration.screenbuffer);
  configuration.screenbuffer = "";
  // move cursor back to the upper corner
  write("\x1b[?25h");
}

void editorScroll() {
  configuration.rx = 0;
  if(configuration.cy < editor.getLineAmount()){
    configuration.rx = convertCxToRx(configuration.cy, configuration.cx);
  }

  if(configuration.cy < configuration.rowoff) {
    configuration.rowoff = configuration.cy;
  }
  if(configuration.cy >= configuration.rowoff + configuration.screenrows) {
    configuration.rowoff = configuration.cy - configuration.screenrows + 1;
  }
  if(configuration.rx < configuration.coloff) {
    configuration.coloff = configuration.rx;
  }
  if(configuration.rx >= configuration.coloff + configuration.screencols) {
    configuration.coloff = configuration.rx - configuration.screencols + 1;
    writeln("coloff from here: ", configuration.coloff);
  }
}

void drawRows() {
  //position the cursor on the top of the screen
  printchars("\x1b[H");

  int y;
  // mydebug("coloff: " ~ to!string( configuration.coloff ) ~ " ");
  // mydebug("cursorX: " ~ to!string( configuration.cx) ~
  //         " cursorY: " ~ to!string(configuration.cy));
  for( y = 0; y < configuration.screenrows; y++) {
    int filerow = y + configuration.rowoff;

    // if no lines, probably no file loaded so show welcome text:
    if(editor.getLineAmount == 1 && y == 0) {
      printchars(centerStr("Welcome to DEdit " ~ EDITOR_VERSION));
    }

    if(y < editor.getLineAmount()) {
      string str = editor.getLine(filerow);
      ulong length = str.length - configuration.coloff;

      if(length > configuration.screencols) {
        length = configuration.screencols;
      }
      if(length < 0) {
        length = 0;
      }

      if(configuration.coloff < str.length) {
        str = str[configuration.coloff..configuration.coloff+length];
        printchars(str);
      }

    } else {
      printchars("~");
    }

    //empty the end of the row
    printchars("\x1b[K");

    // newlines at the end of every line
    printchars("\n");
  }


}

int convertCxToRx(int row, int cx) {
  int rx = 0;
  string str = editor.getLine(row);
  // c as a reference to array char:
  foreach(ref c; str[0..cx]) {
    if(c == '\t') 
      rx += (TAB_STOP - 1) - (rx % TAB_STOP);

    rx++;
  }
  return rx;
}

void drawStatusBar() {
  // invert colors
  printchars("\x1b[7m");

  printchars("File: " ~ editor.getFilename() ~ "");
  printchars("                  ");
  printchars("[" ~ to!string(configuration.cx) ~ "/"
             ~ to!string(editor.getLineLength(configuration.cy) )~ "] ");
  printchars("[" ~ to!string(configuration.cy) ~ "/"
             ~ to!string(editor.getLineAmount()) ~ "]");

  if(DEBUG == 1) {

    //print some debug information
    printchars(printDebug());

  }

  // normal colors
  printchars("\x1b[m");
}

int main(string[] args)
{
  enterRawMode();
	writeln(ostate);
  writeln();
  writeln(nstate);

  // This editor class has text buffer stuff in it.
  editor = new TextEditor();

  initEditor();
  if(args.length > 1) {
    writeln(args[1]);
    editor.loadFile(args[1]);
  }
  clearScreen();

  while(1) {
    updatescreen();
    short status = processKeyPress();

    if(status == EDITOR_QUIT) {
      break;
    }
  }

  clearScreen();
  endRawMode();
  return 0;
}
