//TODO for debugging
import std.stdio;

class TextEditor {

  char[][] content;
  int cursorx;
  int cursory;
  string filename;

  this() {
    content.length = 1;
    content[0].length = 1;
    content[0] = " ".dup;
  }

  void loadFile(string filename) {

    auto file = File(filename);
    this.filename = filename;
    content.length = 0;
    while(!file.eof()) {
      string line = file.readln;
      if(line.length == 0) {
        break;
      }
      string line2 = line[0..$];

      // Strip newlines
      if(line[$-1] == '\n') {
        line2 = line[0..$-1];
      }
      this.putLine(line2);
    }

  }

  string getFilename() {
    return filename;
  }

  char getChar(int line, int col) {
    return content[line][col];
  }


  string getLine(int line) {
    if(line < content.length) {
      return cast(string) content[line];
    }
    return "";
  }


  int getLineLength(int line) {
    if(line < content.length) {
      return cast(int) content[line].length;
    }
    return 0;
  }

  ulong getLineAmount() {
    return content.length;
  }

  void putLine (string str) {
    char[] line = str.dup;
    content.length++;
    content[$-1] = line;
  }

  void putStr(string s, int line, int col) {
    char[] add = s.dup;
    char[] nline;
    nline.length = content[line].length + add.length;
    nline = content[line][0..col] ~ add ~ content[line][col..$];
    content[line] = nline;
  }

  void putChar(char c, int line, int col) {

    if (content.length <= line) {
      content.length = line+1;
    }

    content[line] = content[line][0..col] ~ c ~ content[line][col..$];
  }

  void deleteChar(int line, int col, int direction) {
    if(direction != -1 && direction != 1) {
      return;
    }

    if(col < 1) {
      return;
    }

    content[line] = content[line][0..col+direction] ~ content[line][col..$];
    // content[line].length = 1;
  }

  void divideLines(int line, int col) {
    return;
  }
}
