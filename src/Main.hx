package;

import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import js.Browser;
import js.Lib;
import js.html.AnchorElement;
import js.lib.ArrayBuffer;
import js.html.Element;
import js.html.Event;
import js.html.FileList;
import js.html.FileReader;
import js.html.InputElement;
import js.html.DragEvent;
import js.html.TextAreaElement;
import js.html.Uint8ClampedArray;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	static var navPane:Element;
	static var editor:TextAreaElement;
	static var sources:Vector<String>;
	static function show(s:String) {
		var ace:Dynamic = untyped Browser.window.editor;
		if (ace != null) {
			ace.setValue(s);
			ace.selection.clearSelection();
		} else editor.value = s;
	}
	static function showScript(index:Int, link:AnchorElement) {
		show(sources[index]);
		var cur = Browser.document.getElementById("nav-current");
		if (cur != null) cur.id = null;
		link.id = "nav-current";
	}
	static function readYYDebug(input:YyInput) {
		if (input.readString(4) != "FORM") {
			show("// Supplied file doesn't seem to be a valid GMS debug file.");
			return;
		}
		var eofAt = input.readInt32();
		eofAt += input.position;
		var chunks = new Map<String, Int>();
		while (input.position < eofAt) {
			var chName = input.readString(4);
			var chSize = input.readInt32();
			chunks[chName] = input.position;
			input.position += chSize;
		}
		if (chunks["LOCL"] == null) {
			show("// Supplied file doesn't seem to be a valid GMS debug file.");
			return;
		}
		//trace(chunks);
		//
		input.position = chunks["SCPT"];
		if (chunks.exists("DFNC")) {
			//var scpt = input.readRefCStringVector();
			//Browser.console.log("SCPT", scpt);
			// 2.3 YYDebug files are a trouble!
			// - If there are multiple functions in a script/event, SCPT has repeating entries
			// - LOCL still only has actual sources
			// - A new DFNC chunk only has function names
			// In other words, it's kind of hard to match code to LOCL now!
			// I attempt to do so by ignoring duplicate entries in SCPT.
			// Totally breaks if two scripts/events in a row have identical code tho.
			input.position = chunks["SCPT"];
			var offsets = input.readInt32Vector();
			var last = -1;
			var sourcesArr = [];
			for (offset in offsets) {
				input.position = offset;
				var stringPos = input.readInt32();
				if (stringPos == last) continue;
				last = stringPos;
				input.position = offset;
				sourcesArr.push(input.readRefCString());
			}
			sources = Vector.fromData(sourcesArr);
		} else sources = input.readRefCStringVector();
		for (i in 0 ... sources.length) sources[i] = sources[i].trim();
		/*Browser.console.log("Sources", sources);
		//
		input.position = chunks["DFNC"] + 4;
		var dfnc = input.readRefCStringVector(4);
		Browser.console.log("DFNC", dfnc);
		//
		input.position = chunks["LOCL"];
		var locl = input.readRefCStringVector(4);
		Browser.console.log("LOCL", locl);*/
		//
		input.position = chunks["LOCL"];
		var positions = input.readInt32Vector();
		var doc = Browser.document;
		for (i in 0 ... positions.length) {
			input.position = positions[i] + 4;
			var name = input.readRefCString();
			//trace(positions[i] + 4, name);
			var p1:Int, p2:Int, s1:String;
			if (name.startsWith("gml_Script_")) {
				name = name.substring(11);
			} else if (name.startsWith("gml_Object_")) {
				name = name.substring(11);
				p1 = name.lastIndexOf("_");
				s1 = name.substring(p1 + 1);
				name = name.substring(0, p1);
				p1 = name.lastIndexOf("_");
				name = name.substring(0, p1) + ":" + name.substring(p1 + 1) + ":" + s1;
			} else if (name.startsWith("gml_RoomCC_")) {
				name = name.substring(11);
				p2 = name.lastIndexOf("_");
				p1 = name.lastIndexOf("_", p2 - 1);
				name = name.substring(0, p1) + ":" + name.substring(p1 + 1, p2) + ":" + name.substring(p2 + 1);
			}
			//
			var link = doc.createAnchorElement();
			link.href = "#";
			link.setAttribute("onclick", 'return showScript($i, this)');
			link.appendChild(doc.createTextNode(name));
			navPane.appendChild(link);
		}
		//
		
	}
	static function main() {
		untyped Browser.window.showScript = showScript;
		var doc = Browser.document;
		var body = doc.body;
		navPane = doc.getElementById("nav");
		editor = cast doc.getElementById("source");
		//
		function cancelDefault(e:Event) {
			e.preventDefault();
			return false;
		}
		function handleFiles(files:FileList) {
			for (file in files) {
				var reader = new FileReader();
				reader.onloadend = function(_) {
					navPane.innerHTML = "";
					var abuf:ArrayBuffer = reader.result;
					readYYDebug(new YyInput(Bytes.ofData(abuf)));
				};
				reader.readAsArrayBuffer(file);
			}
		}
		body.addEventListener("dragover", cancelDefault);
		body.addEventListener("dragenter", cancelDefault);
		body.addEventListener("drop", function(e:DragEvent) {
			e.preventDefault();
			handleFiles(e.dataTransfer.files);
			return false;
		});
		//
		var picker:InputElement = cast doc.getElementById("picker");
		picker.addEventListener("change", function(e:Event) {
			handleFiles(picker.files);
		});
	}
}
