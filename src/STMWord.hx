package ;

/**
 * ...
 * @author 
 */

/* stm-word represents the transaction state of an object. 
 * in the pldi06 paper, it is said to consist of two components:
 * 1. a value which is either the version number of the object,
 *    or a pointer to the owning transaction.
 * 2. a bit which tells how to interpret the value: if reset, 
 *    it is a version number, if set, it is a pointer.
 * thus, stm word can be seen as a multiplexer whose output
 * is selected by its bit component. 
 */

/* in this code, we have flattened the representation in 
 * that there are two different fields for the two different interpretations of the value.
 * 
 * version is for the version number, tm is for the pointer to the owning transaction.
 * 
 * flag_owned is the selector bit.
 * there is one additional field node_ulog which is a pointer  to the update-log entry
 * in case the stm-word belongs to an object currently open for update.
 * 
 * it is implicitly mentioned  via the ValidateRead method.
 */
class STMWord
{
	private var flag_owned:Bool;
	private var  tm:TmMgr;
   private var version:Int;
   private var node_ulog:Node_Ulog;

 

   // generic constructor setting each of the fields as desired.
   public function new( tm:TmMgr,   flag:Bool,   v:Int,  n:Node_Ulog)
   {
      setTm(tm);
      setFlagOwned(flag);
      setVersion(v);
      setNodeUlog(n);
   }

 

   /* Equals method is overridden. 
    * If the word belongs to an object not open for update,
    * only the version numbers are compared.
    * If the word belongs to an object open for update,
    * the transaction pointers are compared; that is,
    * return true if they are owned by the same transaction manager.
    */
   public function equals( o:STMWord) :Bool
   {
      return ((this.version == o.version) && (this.flag_owned == false))
          || ((this.tm == o.tm) && (this.flag_owned == true));
   }

   /* cloning is necessary for taking a copy of the 
    * stm word while trying to open its corresponding
    * object for update.
    */
   public function copy( o:STMWord):Void
   {
      this.setTm(o.getTm());
      this.setFlagOwned(o.getFlagOwned());
      this.setVersion(o.getVersion());
      this.setNodeUlog(o.getNodeUlog());
   }

   public function isOwned():Bool { return getFlagOwned(); }

   public function getOwnerFromSTMWord():TmMgr { return getTm(); }

   /* GetNextVersion is called for closing (committing a transaction).
    * after committing, only the version number and the owner flag are
    * relevant; the references for transaction managers and update-log
    * nodes should not matter: they are set to null.
    */
   public function getNextVersion():Void 
   {
      this.tm = null;
      this.flag_owned = false;
      this.version = this.version + 1;
      this.node_ulog = null;
   }

   public function keepVersion():Void
   {
      this.tm = null;
      this.flag_owned = false;
      this.node_ulog = null;
   }

   // needed in ValidateRead.
   public function getEntryFromSTMWord():Node_Ulog { return getNodeUlog(); }

   public function getVersion():Int { return version; }
   public function setVersion(  v:Int):Void { this.version = v; }

   public function getFlagOwned():Bool { return flag_owned; }
   public function setFlagOwned(  flag:Bool) :Void { this.flag_owned = flag; }

   public function getTm():TmMgr { return tm; }
   public function setTm( tm:TmMgr):Void { this.tm = tm; }

   public function getNodeUlog():Node_Ulog { return node_ulog; }
   public function setNodeUlog(  n:Node_Ulog):Void  { this.node_ulog = n; }
}