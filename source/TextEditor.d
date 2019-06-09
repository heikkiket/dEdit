//TODO for debugging
import std.stdio;

class TextEditor {

  char[][] content;
  int cursorx;
  int cursory;

  this() {
    content.length = 1;
    content[0].length = 1;
    content[0] = " ".dup;
  }

  char getChar(int line, int col) {
    return content[line][col];
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
      content.length = line*2;
    }

    if(content[line].length <= col) {
      content[line].length = col * 2;
    }

    content[line][col] = c;
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

  void loadFile(string filename) {

    auto file = File(filename);
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
}
