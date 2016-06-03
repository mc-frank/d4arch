import std.stdio,
	std.getopt,
	std.net.curl,
	std.conv,
	std.string,
	std.file,
	std.json;

import vibe.data.json;

// Input variables
string thread_id;
string board;
string dir = "./save_thread/";
bool save_page = false;

// d4arch usage
string _usage = "Usage: d4arch --thread=[thread_id] --board=[board] --dir=[optional - directory]";

// API URLS
string api_url = "http://a.4cdn.org";
string reply_img_url = "http://i.4cdn.org";
string html_url = "http://boards.4chan.org";
string semantic_url = "";


// Main
void main(string[] args) {

	auto options = getopt(args, "thread", &thread_id, "board", &board, "dir", &dir);

	dir = dir ~ "/";

	if(thread_id.length == 0 || board.length == 0) {
		writeln(_usage);
		exit(-1);
	}

	getThread();

}

// Some voodoo magic type shit happens here
void getThread() {
	string compl_url = api_url ~ "/" ~ board ~ "/thread/" ~ thread_id ~ ".json";
	writeln("URL = ", compl_url);
	auto contents = get(compl_url);

	//vibe-d json implementation
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

	// Save thread replies in .json file
	if(save_page == true) {
		string filename = dir ~ thread_id ~ ".html";
		File page_file = File(filename, "w+");
		string html_url_compl = html_url ~ "/" ~ board ~ "/thread/" ~ thread_id;
		writefln("URL for HTML = %s. In %s", html_url_compl, filename);
		auto page_content = get(html_url_compl);
		page_file.write(page_content);
		page_file.close();
	}
}

// Download image to dir and filename
void getImage(string filename) {

	string URL = reply_img_url ~ "/" ~ board ~ "/" ~ filename;

	if(!dir.exists()) {
		mkdirRecurse(cast(char[]) dir);
	}

	filename = dir ~ filename;

	download(URL, filename);

}
