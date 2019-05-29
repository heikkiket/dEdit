import std.stdio;
import std.ascii;
import std.format;
import std.conv;
import std.string;
import core.stdc.stdio;
import core.sys.posix.termios;
import core.sys.posix.sys.ioctl;
import core.runtime;

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
const short ESC = 27;

const short EDITOR_QUIT = 1005;
const short EDITOR_CONTINUE = 1006;
const short ARROW_UP = 1000;
const short ARROW_RIGHT = 1001;
const short ARROW_DOWN = 1002;
const short ARROW_LEFT = 1003;

const string EDITOR_VERSION = "0.1";

void enterRawMode() {
  tcgetattr(1, &ostate);
  tcgetattr(1, &nstate);
  // cfmakeraw(&nstate);
  //These two flags don't work. I don't know why.
  nstate.c_iflag &= ~(IXON);
  nstate.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
  //nstate.c_cc[VMIN] = 0;
  //nstate.c_cc[VTIME] = 100;
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
  char c;
  readf("%s", &c);
  if(isControl(c)) {

    writeln(c);
    if(cast(short) c == CONTROL_QUIT) {
      writeln("bye!");
      return EDITOR_QUIT;

    }

    printchars("täällä");

  } else {

    switch(c) {
    case 'w':
      return ARROW_UP;
    case 's':
      return ARROW_DOWN;
    case 'd':
      return ARROW_RIGHT;
    case 'a':
      return ARROW_LEFT;
    default:
      return EDITOR_CONTINUE;
      // return cast(int) c;
    }
  }
  return 0;
}


short processKeyPress() {
  int c = readKeyPress();

  switch(c) {
  case EDITOR_QUIT:
    return EDITOR_QUIT;
  case ARROW_UP:
    configuration.cy--;
    break;
  case ARROW_RIGHT:
    configuration.cx++;
    break;
  case ARROW_DOWN:
    configuration.cy++;
    break;
  case ARROW_LEFT:
    configuration.cx--;
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
