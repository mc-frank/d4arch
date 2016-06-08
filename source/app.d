import core.thread,
      std.concurrency,
      std.stdio,
      std.algorithm,
      std.conv,
      std.string,
      std.array,
      std.datetime,
      std.file,
      tkd.tkdapplication,
      vibe.data.json,
      std.net.curl;

// HTML URL
string http_html_url = "http://boards.4chan.org/";
string https_html_url = "https://boards.4chan.org/";

// API URL
string api_url = "https://a.4cdn.org/";
string api_img_url = "https://i.4cdn.org/";

// Application object
class Application : TkdApplication {

  private Entry _thread_entry;
  private Entry _dir_entry;

  private string op_no;
  private string dir;

  override protected void initInterface() {
    this.mainWindow.setTitle("d4arch");
    this.mainWindow.setMinSize(400, 150);
    this.mainWindow.setMaxSize(400, 150);

    //this.createMenu();

    auto textPanel = this.createTextPanel();

    textPanel.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);


    this.setUpKeyBindings();
  }

  private string getAPIUrl(string thread_url) {
    thread_url = thread_url.replace(https_html_url, api_url);
    thread_url = thread_url.replace(http_html_url, api_url);

    // make length of thread_url = 36
    while(thread_url.length != 36) {
      thread_url = thread_url.chop();
    }

    thread_url = thread_url ~ ".json";
    return thread_url;
  }

  private void thread_download(CommandArgs args) {
    //download
    string thread_url = _thread_entry.getValue();
    thread_url = getAPIUrl(thread_url);

    auto contents = get(thread_url);

    //vibe-d json implementation
    string json_string = to!string(contents);
    auto posts = parseJsonString(json_string);

    thread_url = thread_url.replace(api_url, api_img_url);
    while(thread_url.length != 21) {
      thread_url = thread_url.chop();
    }
    writeln("thread_url with img url in = ", thread_url);

    // Loop through each reply checking if there's an image present,
  	// if so get the URL, and call getImage()
  	foreach(reply; posts["posts"]) {
      if( reply["replies"].type() != Json.Type.undefined) {
        op_no = to!string(reply["no"]);
        dir = _dir_entry.getValue() ~ "/"  ~ op_no ~ "/";
      }
  		if( reply["filename"].type() !=  Json.Type.undefined) {

  			string ext = reply["ext"].toString().removechars("\"");
  			string img_file = reply["tim"].toString() ~ ext;

        string img_url = thread_url;
        img_url = img_url ~ img_file;

  			writefln("Downloading: %s", img_file);
  			getImage(img_file, img_url);
  		}
  	}
  }

  void getImage(string filename, string url) {

    if(!dir.exists()) {
      mkdirRecurse(cast(char[]) dir);
    }

    filename = dir ~ filename;

    download(url, filename);

  }

  private void save(CommandArgs args) {
    // save the text
  }

  //
  private void setUpKeyBindings() {
    this.mainWindow.bind("<Control-s>", &this.save);
  }

  private void createMenu() {
    auto menuBar = new MenuBar(this.mainWindow);

    auto fileMenu = new Menu(menuBar, "File", 0)
      .addEntry(new EmbeddedPng!("cancel.png"), "Save", &this.save, ImagePosition.left, "Ctrl-S");
      //.addEntry(new EmbeddedPng!("cancel.png"), "Quit", &this.exitApplication, ImagePosition.left, "Ctrl-Q");
  }

  private Frame createTextPanel() {
    auto widgetPane = new Frame();

    auto thread_entryLabelFrame = new LabelFrame(widgetPane, "Thread URL")
      .pack(10, 0, GeometrySide.top, GeometryFill.x, AnchorPosition.northWest, true);

    this._thread_entry = new Entry(thread_entryLabelFrame)
      .setWidth(0)
      //.appendText("Enter thread URL...")
      .appendText("https://boards.4chan.org/g/thread/51971506/the-g-wiki")
      .pack(5, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.northWest, true);

    auto dirButton = new Button(thread_entryLabelFrame, new EmbeddedPng!("folder.png"), "Directory", ImagePosition.left)
      .setCommand(&this.openDirectoryDialog)
      .pack(5, 0, GeometrySide.right, GeometryFill.y, AnchorPosition.southEast, false);

    this._dir_entry = new Entry(thread_entryLabelFrame)
      .setWidth(10)
      .pack(5, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.southWest, true)//;
      .setValue("/home/frank/saved_thread");

    // Action buttons
    auto downloadButton = new Button(widgetPane, "Download")
      .setCommand(&this.thread_download)
      .pack(5, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.southWest, true);

    auto exitButton = new Button(widgetPane, "Exit")
      .setCommand(&this.exitApplication)
      .pack(5, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.southEast, true);

    return widgetPane;
  }

  private void openDirectoryDialog(CommandArgs args) {
    auto dialog = new DirectoryDialog("Choose directory")
      .setDirectoryMustExist(false)
      .show();

    this._dir_entry.setValue(dialog.getResult());
    this.dir = dialog.getResult();
  }

  private void exitApplication(CommandArgs args) {
    this.exit();
  }

}

// Main entry point
void main(string[] args) {
  auto app = new Application();
  app.run();
}
