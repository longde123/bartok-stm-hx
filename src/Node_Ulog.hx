package ;

/**
 * ...
 * @author 
 */
class Node_Ulog
{

/* the class for update-log entry. 
 * each entry holds the following information:
 * 1. the object whose update is to be undone, held in txo.
 * 2. the stm-word of the object when it was opened
 *    for update.
 * 3. the transaction that opened the object for update.
 * note that, the stm-word w is declared immutable. 
 * this is to prevent accidental tampering of the stm-word
 * whose value is crucial for commitment.
 */

 
	private var txo:TxObj;
   private var  w:STMWord;
   private var tm:TmMgr;

  public function new( txo:TxObj,  w:STMWord,  tm:TmMgr)
   {
      this.setTxo(txo);
      this.setTm(tm);
      this.w = w;
   }

   /* a new STMWord is created starting from the object
    * to open for update. the new stm-word has the same
    * version number; it is owned and the transaction and
    * update-log pointers are set.
    * it might have been a better idea to implement this
    * as a method of STMWord but according to the convention
    * of making the first parameter of the procedure call
    * the owner of the corresponding method
    * we have followed throughout this implementation, 
    * it has to be a method of Node_Ulog.
    */
   public  function makeOwnedSTMWord():STMWord
   {
      return new STMWord(this.tm, true, w.getVersion(), this);
   }

   public function setTxo( txo:TxObj) { this.txo = txo; }
   public function getTxo():TxObj { return txo; }

   public function getW():STMWord { return w; }

   public function setTm( tm:TmMgr):Void { this.tm = tm; }
   public function getTm():TmMgr { return tm; }

	
}