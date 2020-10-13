package;
import haxe.io.BytesInput;
import haxe.Constraints.Constructible;
import haxe.ds.Vector;

/**
 * ...
 * @author YellowAfterlife
 */
class YyInput extends BytesInput {
	public function readInt32Vector():Vector<Int> {
		var n = readInt32();
		var r = new Vector<Int>(n);
		for (i in 0 ... n) r[i] = readInt32();
		return r;
	}
	public function readRefCStringVector(stringOffset:Int = 0):Vector<String> {
		var offsets = readInt32Vector();
		var oldPos = position;
		var strings = new Vector<String>(offsets.length);
		for (i in 0 ... offsets.length) {
			position = offsets[i] + stringOffset;
			strings[i] = readRefCString();
		}
		position = oldPos;
		return strings;
	}
	public function readCString():String {
		var q = position, n = 0;
		while (readByte() != 0) n++;
		position = q;
		var r = readString(n);
		readByte();
		return r;
	}
	public function readRefCString():String {
		var q = position;
		position = readInt32();
		var r = readCString();
		position = q;
		return r;
	}
}
