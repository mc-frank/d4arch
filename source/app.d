import std.stdio,
	std.net.curl,
	std.algorithm.iteration,
	std.conv,
	std.string,
	std.json;

import vibe.data.json;

//
string api_url = "http://a.4cdn.org";
string reply_img_url = "http://i.4cdn.org";
//
string dir = "./thread/";


void main(string[] args) {

	if(args.length < 2) {
		writeln("Usage: d4arch [thread_id] [board]");
		exit(-1);
	}
	if (args[1].length == 1) {
		writeln("Usage: d4arch [thread_id] [board]");
		exit(-1);
	}

	getThread(args[1], args[2]);

}

// Some voodoo magic type shit happens here
void getThread(string thread_id, string board) {
	string compl_url = api_url ~ "/" ~ board ~ "/thread/" ~ thread_id ~ ".json";
	writeln("URL = ", compl_url);
	auto contents = get(compl_url);

	//vibe-d json implementation
	string json_string = to!string(contents);
  auto posts = parseJsonString(json_string);

	foreach(reply; posts["posts"]) {
		if( reply["tim"].type() !=  Json.Type.undefined) {
			string ext = reply["ext"].toString().removechars("\"");
			string img_file = reply["tim"].toString() ~ ext;
			writefln("%s: %s", reply["no"], img_file);
			getImage(img_file, board);
		}
	}

	// Save thread replies in .json file
	string filename = thread_id ~ ".json";
	File f = File(filename, "w+");
	f.write(posts["posts"].toPrettyString());
	f.close();
}

// Download image to dir and filename
void getImage(string filename, string board) {

	string URL = reply_img_url ~ "/" ~ board ~ "/" ~ filename;

	filename = dir ~ filename;

	download(URL, filename);

}
