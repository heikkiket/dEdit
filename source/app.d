import std.stdio : readf, write, writeln, writefln;
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
  int screenrows;
  int screencols;
  int cx, cy;
  string screenbuffer;
}

EditorConfig configuration;

const short CONTROL_QUIT = 17;
const short CONTROL_R = 18;
const short CONTROL_ESC = 27;

const short EDITOR_QUIT = 1005;
const short EDITOR_CONTINUE = 1006;
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

const string EDITOR_VERSION = "0.1";

void enterRawMode() {
  tcgetattr(1, &ostate);
  tcgetattr(1, &nstate);
  // cfmakeraw(&nstate);
  //These two flags don't work. I don't know why.
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
}

int readKeyPress(){
  int c;
  c = fgetc(stdin);

  if( c == -1) {
    return EDITOR_CONTINUE;
  }

  if(isControl(c)) {
      int[3] res;
    // writeln("is control. ");

    // The fgetc function returns -1 if no result
    res[0] = fgetc(stdin);
    res[1] = fgetc(stdin);
    // Debug:
    // writefln("%d %d %d", c, res[0], res[1]);

    if(cast(short) c == CONTROL_QUIT) {
      writeln("bye!");
      return EDITOR_QUIT;

    }

    // 9 Tab
    // 127 Backspace

    if(res[0] == 91) {
      switch(res[1]) {
        // 72 Home
        // 70 End
        // 51 delete
        // 53 pgup
        // 54 pgdown
      case 65: return ARROW_UP;
      case 66: return ARROW_DOWN;
      case 67: return ARROW_RIGHT;
      case 68: return ARROW_LEFT;
      default: return EDITOR_CONTINUE;
      }
    }


  } else {
    char[1] par = cast(char) c;
    printchars(cast(string) par);
  }
  return 0;
}

void moveCursor(int key) {
  final switch(key) {
  case ARROW_UP:
    if(configuration.cy > 0) {
      configuration.cy--;
    }
    break;
  case ARROW_RIGHT:
    if(configuration.cx < configuration.screencols) {
      configuration.cx++;
    }
    break;
  case ARROW_DOWN:
    if(configuration.cy < configuration.screenrows) {
      configuration.cy++;
    }
    break;
  case ARROW_LEFT:
    if(configuration.cx > 1) {
      configuration.cx--;
    }
    break;
  }
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
    moveCursor(c);
    break;
  default:
    return EDITOR_CONTINUE;
  }
  return 0;
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
  write("\x1b[?25l");

  drawRows();

  printchars(format("\x1b[%d;%dH", configuration.cy + 1, configuration.cx + 1));

  write(configuration.screenbuffer);
  configuration.screenbuffer = "";
  write("\x1b[?25h");
}

void drawRows() {
  int y;
  for( y = 0; y < configuration.screenrows; y++) {
    printchars("~");
    //empty the following row
    printchars("\x1b[K");

    if(y < configuration.screenrows - 1) {
      printchars("\n");
    }
  }
  //Reposition the cursor on the top of the screen
  printchars("\x1b[H");
}

int main()
{
  enterRawMode();
	writeln(ostate);
  writeln();
  writeln(nstate);

  initEditor();
  clearScreen();

  while(1) {
    printchars(centerStr("Welcome to DEdit " ~ EDITOR_VERSION) ~ "\n");
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

int main2() {

  enterRawMode();
  while(1) {
    int i = readKeyPress();

    if( i == EDITOR_QUIT) {
      break;
    }
  }

  return 0;
}
