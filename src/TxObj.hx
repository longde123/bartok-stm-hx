package ; 
import neko.vm.Mutex;
/**
 * ...
 * @author 
 */
class TxObj
{
      
   private var s:Snapshot;
   private var o:Dynamic; 
   private var mutex:Mutex;
   /* the constructor creates a new TxObj for the object o
    * whose class is given by type. as this is the first
    * time the object is going to be used in a transaction,
    * its version number is set to be 0. to that end, a new
    * stm-word for an unowned object with version 0 is created
    * and then a snapshot holding this reference is created. 
    */

  public function new(  o:Dynamic )
   {
	 mutex = new Mutex();
      this.setO(o); 
	  var s_init:STMWord = new STMWord(null, false,0,null);
      this.s = new Snapshot(s_init);
   }

   public function getSTMWord():STMWord { 
	   return s.toWord(); 

	   }

   public  function getSTMSnapshot():Snapshot { 
	 
		 return s; 
   	 
		 }

   /*********************************************************/
   // this method should be atomic: according to the pldi06 
   // paper, it should mimic an atomic CAS.
   /*********************************************************/
   /* if the stm-word oldw is the same as the current stm-word in
    * the object's snapshot, then the object's snapshot is changed
    * to neww, an stm-word to make the object owned and pointing
    * to the owning transaction.
    * note that, the reference s does not change.
    * the reference to s.w does not change either.
    */
   /*********************ATOMIC-BEGIN************************/
 
   public function openSTMWord( oldw:STMWord,  neww:STMWord):Bool
   { 
      var f:Bool = false;
	  mutex.acquire();
      if (s.toWord().equals(oldw))
      {
         s.setSTMWord(neww);
         f = true;
      }
	   mutex.release();
      return f;
	 
   }
   /*********************ATOMIC-END**************************/

   /* initially, following OpenSTMWord which requires a CAS-like
    * implementation, CloseSTMWord also was a synchronized method.
    * however, the paper makes no suggestion about restricting its possible
    * interleavings. so, for now, the synchronized declaration
    * is commented out.
    */
   //  [MethodImpl(MethodImplOptions.Synchronized)]

   /* called for releasing an owned object. the stm-word next
    * should hold the correct version number and its pointers 
    * should be set to 0 by the caller. 
    * note that, CloseSTMWord is called on commit,
    * or on abort. during the former, next will have a new version
    * number; during the latter, the version number remains the
    * same. to achieve this, the first is done via STMWord.GetNextVersion
    * method while the second is done via STMWord.KeepVersion.
    * neither creates new references but changes the values in place.
    */
   public function closeSTMWord( next:STMWord):Void
   {
      s.setSTMWord(next);
   }

   public function setO(  o:Dynamic):Void { this.o = o; }
   public function getO():Dynamic { return o; }

 
	
}