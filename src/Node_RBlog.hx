package ;

/**
 * ...
 * @author 
 */
class Node_RBlog
{
 
/* the class for undo-log entry. 
 * each entry holds the following information:
 * 1. the object that is being updated, held in txo.
 * 2. the field of the object that is updated, 
 *    held in mem.
 * 3. the overwritten value, held in prev.
 * for simplicity, method calls are ignored.
 */
	
	private var txo:TxObj;
	private var mem:String;
	private var prev:Dynamic;
	
	public function new( txo:TxObj,   mem:String,   prev:Dynamic) {
		this.setTxo(txo);
		this.setMem(mem);
		this.setPrev(prev);
	}

	public function setTxo( txo:TxObj) { this.txo = txo;	}
	public function getTxo() :TxObj{ return txo;	}

	public function setMem(  mem:String):Void { this.mem = mem; }
	public function getMem():String { return mem;	}

	public function setPrev(  prev:Dynamic):Void { this.prev = prev; }
	public function getPrev():Dynamic { return prev; }

}