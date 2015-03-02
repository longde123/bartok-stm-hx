package ; 
	  /* the heap is represented as a collection of instances
    * of a single representative class, DummyClass. it has
    * a single field, f, and accessor methods for it. 
    * f is declared public as the reflection methods to read
    * from or write into that field need the field and invoking
    * methods seemed much uglier than this.
    */
     class DummyClass
   {
      public var f:Dynamic;
	  public function new() {
		  f = 0;
	  }
   }
  
/**
 * ...
 * @author 
 */
class STMAdapter
{

 


   /* heap is actually a shared ArrayList; for testing purposes
    * it is declared here. eventually, it will move into the
    * initialization of the overall program; will be static and
    * will be shared among all active threads.
    */
   private var heap:MyHeap<TxObj>;

   /* the main driver for this implementation will be creating
    * an undetermined number of transactions each of which will
    * start transactions, commit transactions, read or write shared
    * objects. these operations will be done non-deterministically
    * and nd is the main variable for pseudo-randomness used for
    * this non-determinism.
    */
   private var nd:Random;

   /* each thread has its own transaction manager. 
    * eventually, this declaration should move to the thread 
    * initialization code.
    */
   private var tmmgr:TmMgr;

   /* a simple counter to keep track of the current number of 
    * open transactions. only a successful commit decrements the
    * counter. each transaction beginning increments the counter.
    * it is thread local.
    */
   private var opencnt:Int;

   /* the class contructor expects valid TmMgr and MyHeap
    * instances. Each thread has its own TmMgr so the
    * thread initialization routine is responsible for
    * TmMgr instance. MyHeap is a shared array which
    * should be visible to all the threads.
    * the random generator and the number of open transactions
    * are also initialized here.
    */
   public function new( tmmgr:TmMgr,  heap:MyHeap<TxObj>)
   {

      this.heap = heap;
      nd = new Random();
      this.tmmgr = tmmgr;
      opencnt = 0;
   }

   /* called for starting a transaction. it simply
    * increments the number of open transactions by 1,
    * and then invokes the relevant method from TmMgr.
    */
   public function beginXact():Void
   {
      opencnt++;
      tmmgr.beginXact();

   }

   /* called for committing a transaction. it in turn
    * calls the CommitXact of TmMgr which does all 
    * the necessary commitment work.
    * note that, the number of open transaction count
    * is decremented only if the transaction successfully
    * commits; otherwise, the current transaction rolls 
    * back to its beginning state and remains active.
    */
   public function commitXact():Void
   {
     
      tmmgr.commitXact();
      opencnt--;
   }



   // Auxiliary read and write methods for the object fields

   public function doRead( txo:TxObj,   field_string:String):Dynamic
   { 
      return Reflect.field(txo.getO(), field_string); 
   }


   // Auxiliary method for writing; should be called within transactions
   /* if the object is owned by this transaction, the old value is logged 
    * in undo-log (rblog), and the new value is written in-place. 
    * if the object is not owned or owned by another transaction, currently
    * nothing is being done. obviously, since before updating an object,
    * it should be opened for update and if the opening fails, the transaction 
    * should abort. hence, correct usage dictates the else part to be never
    * reached.
    * the previous value of txo.field should be stored in the undo-log,
    * but no need to call it here as it should be called explicitly by the
    * system (bartok-stm should place an explicit call to the method).
    */

   public function doWrite( txo:TxObj,   field_string:String,   val:Dynamic):Void
   { 
      //var s :STMWord = txo.getSTMWord();
     //  trace((s.isOwned() && s.getTm() == this.tmmgr));

      // Assertion violation means trouble - either the txo was 
      // not opened for update previously
      // or even worse, the txo is opened by some other xaction.
	 
		Reflect.setField(txo.getO(), field_string, val); 
   }

   /* non-deterministically write to a TxObj a
    * non-deterministic value. the TxObj could be
    * an already created reference or a new one. 
    * note that, if the acquiring of the TxObj fails
    * exception will be thrown by DTMOpenForUpdate, 
    * it will be caught here and DTMAbort will be called.
    */
   public function NDWrite():Void
   {
      var dxo:TxObj = NDSelect();
      var toWrite:Dynamic = (nd.next());
      try
      {
         tmmgr.openForUpdate(dxo);
         tmmgr.logFieldStore(dxo, "f");
         doWrite(dxo, "f", toWrite);
		 
      }
      catch ( e:AtomicIsInvalidException)
      {
		  // trace(e);
        tmmgr.abort();
     }
	    
   }


   /* non-deterministic access to an object,
    * either among the currently active ones or
    * a fresh one. this nondeterministic choice is
    * done via NDSelect.
    * the read value is irrelevant for our purposes
    * and ignored.
    * note that, following the semantics given
    * in the paper, read does not cause any abort
    * signal; each access succeeds.
    */
   public function NDRead():Dynamic
   {
      var dxo:TxObj = NDSelect();
      tmmgr.openForRead(dxo);
      var dummy = doRead(dxo, "f");
      return dummy;
   }

   /* non-deterministic selection of a shared object,
    * either already existing or new. 
    * note that, the heap is actually a collection of
    * TxObj's which wrap an ordinary class with some
    * bartok specific information, namely the snapshot.
    */
   private  function NDSelect():TxObj
   {
      var curheapsize:Int = heap.size();
      var d:DummyClass;
      var dxo:TxObj;
      var newObject:Bool = (curheapsize == 0) || (nd.next(2) == 1);

      // newObject == 1 if NDSelect is going to return a new object
      // that was not in the heap when NDSelect was called. 

      // for debugging
      // newObject = true;
      if (newObject)
      {
         d = new DummyClass();
         dxo = new TxObj(d );
         heap.add(dxo);
      }
      else
      {
         var idx:Int = Std.int(nd.next(curheapsize));
		 idx = Std.int(Math.min(idx, curheapsize-1));		
         dxo = heap.get(idx);
      }
      return dxo;
   }

}