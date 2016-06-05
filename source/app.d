import std.stdio,
      std.string,
      std.getopt,
      std.conv,
      std.net.curl,
      std.file,
      std.json,
      dlangui;

import vibe.data.json;

mixin APP_ENTRY_POINT;

// Input variables
string thread_id;
string board;
string dir = "./saved_thread";
string dir_temp;
bool save_page = false;
bool nogui = false;

// Usage
string _usage = "Usage: d4arch --thread=[thread_id] --board=[board] --dir=[optional - directory] --nogui [optional]";

// API URLs
string api_url = "http://a.4cdn.org";
string reply_img_url = "http://i.4cdn.org";
string html_api_url = "http://boards.4chan.org";

// entry point for dlangui based application
extern (C) int UIAppMain(string[] args) {

  auto options = getopt(args, "thread", &thread_id, "board", &board, "dir", &dir_temp, "nogui", &nogui);

  if(nogui == false) {
    // create window
    Log.d("Creating window");
    if(!Platform.instance) {
      Log.e("Platform.instance is null!!!");
    }

    Window window = Platform.instance.createWindow("d4arch", null, WindowFlag.Resizable, 340, 200);
    //Window window = Platform.instance.createWindow("d4arch", null);
    Log.d("Window created");

    // create a widget to show in window
    window.mainWidget = parseML(q{
      VerticalLayout {
        margins: 0
        padding: 0
        layoutWidth: fill
        backgroundColor: "#EEAA88"

        // Top label
        TextWidget { padding: 5; text: "d4arch"; textColor: "black"; fontSize: 150% }

        // Thread and board stuff
        TableLayout {
          padding: 5
          colCount: 2
          layoutWidth: fill
          TextWidget { text: "Thread ID:" }
          EditLine { id: threadText; layoutWidth: fill }
          TextWidget { text: "Board ID:" }
          EditLine { id: boardText }
          TextWidget { text: "Directory:"}
          EditLine { id: dirText }
          TextWidget { text: "Save Page [not working]:"; textColor: "black"; fontSize: 100% }
          CheckBox { id: savePage }
        }

        // Some spacing
        VSpacer {
          layoutWidth: FILL_PARENT
        }

        // Action buttons
        HorizontalLayout {
          padding : 10
          Button { id: btnDownload; text: "Download" }
          Button { id: btnCancel; text: "Close" }
        }
      }
    }
    );


    auto thread_edit = window.mainWidget.childById!EditLine("threadText");
    auto board_edit = window.mainWidget.childById!EditLine("boardText");
    auto dir_temp_edit = window.mainWidget.childById!EditLine("dirText");

    // Get the thread
    window.mainWidget.childById!Button("btnDownload").click = delegate(Widget w) {
      thread_id = to!string(thread_edit.text);
      board = to!string(board_edit.text);
      dir_temp = to!string(dir_temp_edit.text);

      if(thread_id.length == 0 || board.length == 0 || dir_temp.length == 0) {
        window.showMessageBox(UIString("Error"d), UIString("Please complete thread data"d));
        return true;
      }

      if(dir.length == 0) {
        dir = dir ~ thread_id ~ "/";
      }
      else {
        dir = dir ~ "/" ~ dir_temp ~ "/";
      }
      //writeln("DIR = ", dir);

      getThread();
      //window.showMessageBox(UIString("Download Dialog"d), UIString("Thread ID = "d ~ to!dstring(thread_id) ~ "\nBoard ID = "d ~ to!dstring(board_id)));
      window.showMessageBox(UIString("Downloaded"d), UIString("Completed."d));
      return true;
    };

    // close window on Cancel button click
    window.mainWidget.childById!Button("btnCancel").click = delegate(Widget w) {
      window.close();
      return true;
    };


    window.show();

    return Platform.instance.enterMessageLoop();
  }

	// when nogui is set
  else if(nogui == true) {
    if(thread_id.length == 0 || board.length == 0) {
      writeln("Thread or board is incorrect");
      return true;
    }

    if(dir_temp.length == 0) {
      dir = dir ~ "/" ~ thread_id ~ "/";
    }
    else {
      dir = dir ~ "/" ~ dir_temp ~ "/";
    }
    writeln("dir = ", dir);
    getThread();
  }

  return 0;
}

void getThread() {
  //getHTMLPage();
  string compl_url = api_url ~ "/" ~ board ~ "/thread/" ~ thread_id ~ ".json";
  writeln("URL = ", compl_url);
  auto contents = get(compl_url);

  // vibe-d json implementation
  string json_string = to!string(contents);
  auto posts = parseJsonString(json_string);

  // Loop through each reply checking if there's an image present,
	// if so get the URL, and call getImage()
	foreach(reply; posts["posts"]) {
		if( reply["filename"].type() !=  Json.Type.undefined) {
			string ext = reply["ext"].toString().removechars("\"");
			string img_file = reply["tim"].toString() ~ ext;
			writefln("Downloading: %s", img_file);
			getImage(img_file);
		}
	}
}

void getHTMLPage() {
  string compl_json_url = api_url ~ "/" ~ board ~ "/" ~ thread_id ~ ".json";
  auto json_contents = get(compl_json_url);

  string semantic_url;
  // vibe-d json implementation
  string json_string = to!string(json_contents);
  auto posts = parseJsonString(json_string);

  foreach(reply; posts["posts"]) {
    if( reply["semantic_url"].type() != Json.Type.undefined) {
      semantic_url = reply["semantic_url"].toString();
    }
  }

  string compl_html_url = html_api_url ~ "/" ~ board ~ "/" ~ thread_id ~ "/" ~ semantic_url ~ ".html";
  writeln("compl_html_url = ", compl_html_url);
  auto html_contents = get(compl_html_url);

  download(compl_html_url, "index.html");

}

void getImage(string filename) {
  string URL = reply_img_url ~ "/" ~ board ~ "/" ~ filename;

  if(!dir.exists()) {
		mkdirRecurse(cast(char[]) dir);
	}

	filename = dir ~ filename;

	download(URL, filename);
}
