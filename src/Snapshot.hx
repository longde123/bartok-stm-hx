package ;

/**
 * ...
 * @author 
 */
class Snapshot
{

 
	/* snapshot, according to the pldi06 paper, is
    * responsible for holding run-time information as well.
    * in this code, the additional piece of run-time 
    * information is ignored for simplicity. 
    */
   private var w:STMWord;
 
   public function new(? w:STMWord) { 
	   if (w == null) this.w = new STMWord(null, false, 0, null);
	   else this.w = w; 
	}

   /* comparison of snapshots is done based on value, 
    * and not on reference. the Equals method in turn
    * calls the Equals method of the stm-word. 
    */
   public function equals( o:Snapshot):Bool
   {
      return this.w.equals(o.w);
   }

   /* cloning of a snapshot calls the cloning of
    * the stm-word that the snapshot contains. 
    */
   public function copy( o:Snapshot):Void
   {
      w.copy(o.toWord());
   }

   public function toWord() :STMWord{ return w; }

   /* in place update of the stm-word. the reference
    * to the stm-word does not change.
    */
   public function setSTMWord( w:STMWord):Void {
	  
	   this.w.copy(w);
	}
}