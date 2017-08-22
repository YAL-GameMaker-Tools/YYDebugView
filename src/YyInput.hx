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
