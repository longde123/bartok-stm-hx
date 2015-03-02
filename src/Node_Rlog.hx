package ;

/**
 * ...
 * @author 
 */
class Node_Rlog
{
/* the class for read-log entry.
 * each entry holds the following information:
 * 1. the object that is read, held in txo.
 * 2. the snapshot of the object at the time
 *    of read, held in s.
 * the snapshot s will be used to decide
 * whether the read was consistent at the time of
 * commitment via ValidateRead.
 */
 
	private var txo:TxObj;
	private var  s:Snapshot;
		
	public function new ( txo:TxObj,  s:Snapshot) {
		this.setTxo(txo);
		this.s = s; 
	}

	public function setTxo( txo:TxObj) {	this.txo = txo;	}
	public function getTxo() :TxObj{ return txo;	}

	public function getS():Snapshot{ return s; }
	
}