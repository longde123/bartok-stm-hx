package ;
 
/* this is the class implementing the transaction manager.
 * each thread is expected to have a transaction manager of
 * its own. a transaction manager has three logs following
 * the pldi06 paper: read-log, update-log, undo-log. 
 * it also has a stack-like structure holding pointers
 * to these logs in order to keep track of the nested
 * transactions and to correctly roll-back or commit these
 * nested transactions.
 */
/* currently, nested transactions are not supported. */

class TmMgr
{
 /* an auxiliary variable is kept. there was an ambiguous 
    * line in the pseudo-code of the pldi06 paper for 
    * ValidateRead. One interpretation of that line misses
    * a corner case which results in the validation of an 
    * otherwise invalid transaction. if buggy is set to true,
    * this bug is present. 
    */
   private var BUGGY :Bool ;

   /* watermark is a list of triples (r,u,rb) all of which
    * are pointers. r is a pointer to a node in the read-log;
   * u is a pointer to a node in the update-log; rb is a
   * pointer to a node in the undo-log. 
   * the motivation for this "meta" information is to handle
   * nested transactions. the last watermark node points
   * to the most recent node of each log prior to the beginning
   * of the current transaction.
   * each thread has its own local copy of watermark as logs
   * are also thread-local structures. 
   */
   //private LinkedList<Node_MetaXact> watermark;

   private var  ulog:List<Node_Ulog>;
   public function getUlog():List<Node_Ulog>  { return ulog; }
   private var  rlog:List<Node_Rlog>;
   public  function getRlog() :List<Node_Rlog>{ return rlog; }
   private var rblog:List<Node_RBlog>;
   public function getRBlog():List<Node_RBlog> { return rblog; }

   /* Class constructor initializes the logs and inserts
    * sentinel nodes in each to prevent unnecessary emptiness
    * checks.
    */
   public function new()
   {
      //watermark = new LinkedList<Node_MetaXact>();

      ulog = new List<Node_Ulog>();
      //Node_Ulog usentinel = new Node_Ulog(null, null, null);
      //ulog.AddFirst(usentinel);

      rlog = new List<Node_Rlog>();
      //Node_Rlog rsentinel = new Node_Rlog(null, null);
      //rlog.AddFirst(rsentinel);

      rblog = new List<Node_RBlog>();
      //Node_RBlog rbsentinel = new Node_RBlog(null, null, null);
      //rblog.AddFirst(rbsentinel);

      // by default, we will ignore the bug.
      BUGGY = false;
   } 


   /* called to start a transaction by the user. 
    * increments the number of open/nested transaction
    * count, opencnt, by 1,
    * creates a new meta-xact node pointing to the last 
    * node of each log and appends it to the watermark list,
    * and finally calls DTMStart().
    */
   public function beginXact():Void
   {

      //Node_MetaXact m = new Node_MetaXact(rlog.Last.Value,
      //                                     ulog.Last.Value,
      //                                     rblog.Last.Value);
      //watermark.AddLast(m);
		start();
   }

   /* if commitment succeeds, fine; just remove the last 
    * watermark node. 
    * if commitment fails, the current transaction remains:
    * the watermark node is not removed, as the transaction
    * remains active.
    * all the rolled-back instructions are ignored.
    */
   public function commitXact():Void
   {
       commit();
   }


   /* following the pseudo-code given in the pldi06 paper,
    * the read-log only records the current snapshot and
    * the corresponding object. 
    * during read-validation, the snapshot values will
    * be compared. if no update has taken place, the values
    * will be equal; otherwise, the reason why the snapshots 
    * are different will be examined and decided accordingly.
    * note that, s is initialized with dummy values and 
    * the snapshot of the object to be read is copied into
    * s. getting a copy of the reference to the snapshot 
    * of txo by the assignment
    *   s = txo.GetSTMSnapshot();
    * will void all the snapshot checks done in 
    * ValidateRead: all the comparisons between the old
    * and the current snapshot will yield true.
    */

   public function openForRead( txo:TxObj):Void
   {
      var s:Snapshot = new Snapshot(null); 
      s.copy(txo.getSTMSnapshot());
      var n:Node_Rlog = new Node_Rlog(txo, s);
      rlog.add(n);
   }


   /* if txo is not owned by any other transaction, it will be owned
    * by this transaction. in case txo is currently free (txo.IsOwned() == false)
    * a new update log node is created which points to the candidate owning 
    * transaction, to the stm-word of txo and the txo itself. then, a new
    * stm-word is created which points to this transaction, is owned, has 
    * the same version number and points to the new update log node.
    * if the state of the txo has not changed upto this point, its stm-word
    * is replaced by this new stm-word. 
    * note that, the stm-word held in txo represents the current state of txo.
    * the stm-word held in the update-log entry represents the state of txo
    * at the time of acquiring. both will be used during read validation. 
    * the former will depict the current state of the object, whether it is
    * owned by any transaction or not; the latter will help decide whether
    * the ordering of reads and the acquiring of txo allows commitment.
    */
   /*
    * to take care of GetEntryFromSTMWord which is supposed to return the 
    * update node corresponding for a given stm-word, we placed a reference to 
    * the update-log node. 
    */
   /* originally, the method does not return any value. however,
    * to communicate between this method and the caller STMAdapter
    * in case of unsuccessful opening (txo owned by some other transaction), 
    * a boolean value is being returned: true, signaling successful 
    * acquire; false, failed acquire, of the txo.
    */

   public function openForUpdate( txo:TxObj):Void
   {
      // create stm_word with default dummy values
      var stm_word:STMWord = new STMWord(null, false, 0, null);
      // and copy the contents of the stm-word of the object into stm_word
      stm_word.copy(txo.getSTMWord());

      if (!stm_word.isOwned())
      {  // the object was not owned by any transaction

         // create a new update-log entry which points to the object to
         // the object to be updated, has a copy of its stm-word and
         // points to this transaction manager which is candidate for
         // owning the object. 
         // the object's state does not change after executing this line.
         var n:Node_Ulog = new Node_Ulog(txo, stm_word, this);

         // create a new stm-word, new_stm_word, whose version number
         // is the same as that of stm_word, points to the this
         // transaction as the owner of its associated word, 
         // points to this update-log entry and has its owned bit set.
         // the call is equivalent to the declaration below
         // STMWord new_stm_word = new STMWord(this,          // reference for this xact manager
         //                          true,                    // the object is now owned
         //                          stm_word.getVersion(),   // the version remains the same
         //                          n);                      // the update entry link
         //
         // in short, new_stm_word is the stm-word that will be held in
         // txo if its acquiring by this transaction is successful.
         // the object's state does not change after executing this line.
         var new_stm_word:STMWord = n.makeOwnedSTMWord();

         // a check to see whether the state of the object has changed
         // since the read of its stm-word at the beginning of this method.
         // OpenSTMWord implements a CAS: if the stm-word read from txo
         // is the same as stm_word, new_stm_word becomes the new stm-word
         // of txo.
		// var lock:Lock = new Lock();
         if (txo.openSTMWord(stm_word, new_stm_word))
         {  // CAS was successful.

            // the state of the object has now changed: it is now 
            // owned by this transaction.
            ulog.add(n);
         }
         else
         {  // failed to acquire the object; some other transaction seems

            // to have acquired txo before this transaction.
            // note that, control will be here, even if txo is currently 
            // not owned by any other transaction but a transaction has
            // acquired it and committed or aborted between the first read
            // of txo and the second read, attempting the CAS.
            // abort the transaction.
            becomeInvalid();
         }
		 //lock.release();
      }

      // the object was owned. we have to decide whether the owner is 
      // this transaction or some other transaction.
      else if (stm_word.getOwnerFromSTMWord() == this)
      {  // this transaction has already acquired txo.

         // nothing more to do.
      }
      else
      {  // some other transaction has acquired txo.

         // abort the transaction.
         becomeInvalid();
      }
   }

   /* DTMLogFieldStore is called for the undo-log. whenever an object
    * is updated, its previous value should be recorded into the
    * undo-log. 
    * txo is the object to be updated, field_string is the name
    * of the field of txo to written into.
    * if txo is not owned by this transaction, 
    * this method should not have been called in the first place.
    * appropriate error checks might be eventually needed here. 
    */
   public  function logFieldStore( txo:TxObj,   field_string:String):Void
   {
      // read the old value of the field to be updated.
	 
      var oldval:Dynamic = Reflect.field(txo.getO(), field_string);

      // create a new undo-log entry with the name of the object,
      // its field to be updated and the overwritten value.
      var n :Node_RBlog= new Node_RBlog(txo, field_string, oldval);

      // append the new entry into the undo-log.
      rblog.add(n);
   }


   /* the method to abort a transaction. 
    * note the order between Rollback and ReleaseUpdated.
    * Rollback puts the updated objects into their 
    * pre-transaction state, ReleaseUpdated releases these 
    * updated objects. 
    */
   public function abort():Void
   {
      // get the watermark node for this transaction.
      // Node_MetaXact n = watermark.Last.Value;

      // clear the read log up to the beginning of this transaction.
      // ClearReadLog(n.getRmark());
      clearReadLog();

      // undo the changes made by this transaction.
      // Rollback(n.getRbmark());
      rollback();

      // release all the objects acquired by this transaction.
      // ReleaseUpdated(n.getUmark());
      releaseUpdated();

      // notify the main loop that the transaction had to commit.
      // caught in the thread's transaction loop defined in TestHarness.
      // also caught at the top level in RunXaction of TestHarness.
      // read cannot be validated.
      throw new AtomicIsInvalidException();
   }

   /* clears all the entries of the read-log inserted by the
    * current transaction that is being aborted. 
    */
   // private void ClearReadLog(Node_Rlog r)
   private function clearReadLog():Void
   {
      // remove all the entries upto, not including the
      // last read-log entry of the nesting transaction.
      // while (rlog.Last.Value != r)
		rlog.clear();
   }

   /* clears the undo-log entries of the current transaction that
    * has successfully committed.
    */
   // private void ClearRollbackLog(Node_RBlog rb)
   private function clearRollbackLog():Void
   {
      // remove all the entries upto, not including the
      // last undo-log entry of the nesting transaction.
      // while (rblog.Last.Value != rb)
      rblog.clear();
   }

   /* restores the objects acquired by this transaction that is
    * aborting to their last states right before their acquirement
    * by this transaction.
    */
   // private void Rollback(Node_RBlog rb)
   private function rollback():Void
   {
      // keep undoing until the undo-entry of the nesting
      // transaction is reached.
      // while (rblog.Last.Value != rb)
	  
	  
      while (!rblog.isEmpty())
      {
         // get the current undo-log entry; they are being
         // fetched in reverse chronological order.
         var n:Node_RBlog = rblog.last();

         // get the txo whose entry is to be restored.
         var txo:TxObj = n.getTxo();

         // get the field updated.
         var f :String= n.getMem();

         // get the value overwritten.
         var v:Dynamic = n.getPrev();

         // get the type of the object wrapped in txo.
         // currently, redundant as there is only one DummyClass.
         

         // get the object itself.
         var o:Dynamic = txo.getO();

         // restore the overwritten value. 
		 Reflect.setField(o, f, v); 

         // clear this undo-log entry.
         rblog.remove(rblog.last());
      }
   }

   /* the objects acquired by this transaction that is
    * aborting are released. 
    */
   // private void ReleaseUpdated(Node_Ulog u)
   private function releaseUpdated()
   {
      // keep doing this until the update-log entry
      // of the nesting transaction is reached.
      // while (ulog.Last.Value != u)
      while (!ulog.isEmpty() )
      {
         // get the current update-log entry.
         // the reverse chronological order used here is
         // not crucial; any other order would do just as well.
         var n :Node_Ulog= ulog.last();

         // get the stm-word of the object holding the state
         // right before being acquired.
         var w :STMWord= n.getW();

         // get the txo to which this update-log entry corresponds.
         var txo:TxObj = n.getTxo();

         // update the stm-word so that its flag is reset to false, 
         // its node and transaction pointers are reset to null,
         // and its version remains unchanged.
         /* w.KeepVersion(); */
         // it turns out that even in aborts, the version number
         // is incremented to account for a certain corner case
         // that will be impossible to catch during read validation
         // if the version number remains the same after abort.
         // so, we will call the version incrementing version.
         w.getNextVersion();

         // change the snapshot of txo with this new stm-word. 
         // note that CloseSTMWord does an in-place update; 
         // the reference does not change.
         // after executing this line, txo's state changes.
         // it moves from being owned to being free.
         txo.closeSTMWord(w);

         // the update-entry can now be removed.
         ulog.remove(ulog.last());
      }
   }

   /* to notify the caller that the transaction has to 
    * be aborted. this exception is caught within DTMIsValid.
    */
   public function becomeInvalid():Void
   {
      throw new AtomicIsInvalidException();
   }

   /* this method is called for each object read by the
    * current transaction trying to commit. depending on
    * the state at the time of read, the current state and
    * if also updated by this transaction, the state at the
    * time of update, the read is either validated or invalidated
    * which in turn aborts the transaction. 
    */

   public function validateReadObject( n:Node_Rlog):Void
   {
      // read the state of the object at the time of read.
      var olds :Snapshot= n.getS();

      // get the object read.
      var txo:TxObj = n.getTxo();

      // get the current state of the object.
 
      var curs:Snapshot = txo.getSTMSnapshot();

      // in the present implementation, the difference
      // between the snapshot and the stm is superfluous.
      // nevertheless, to make this implementation look similar
      // to the pseudo-code given in the pldi06 paper,
      // we are using both the snapshot and its corresponding
      // stm-word.
      var curw :STMWord= curs.toWord();

      /* the Snapshot.Equals method calls the STMWord.Equals 
       * method and will return true if both the version
       * number and the update-log entry pointers are the
       * same. That is, if the object is not open for update,
       * it will return true if the version numbers are the same.
       * If the object is open for update, it will return true
       * if, additionally, the update-log pointers are 
       * pointing to the same update-log entry.
       */

      if (olds.equals(curs))
      {  // the snapshot did not change

         // check the current state of txo
         if (!curw.isOwned())
         {  // it was never open for update -> no conflict

         }

         // txo is currently owned... by this transaction?
         else if (curw.getOwnerFromSTMWord() == this)
         {  // it was opened for update by this transaction

         }

         else
         {  // it was opened for update by another transaction
            // that transaction has not aborted/committed yet.

            // abort the transaction.
            becomeInvalid();
         }
      }
      else
      {
         // the snapshot has changed. either the version number is
         // different or the update-log pointer is different.
         //
         var oldw:STMWord = olds.toWord();
         if (!oldw.isOwned())
         {  // the object was not open for update at the time of
            // opening it for read.

            if (oldw.equals(curw))
            {  // irrelevant for the current implementation; inflation
               // is not implemented. if snapshots are different, 
               // stm-words cannot be the same, evidenced by the fact
               // that Snapshot.Equals calls STMWord.Equals and does
               // nothing else.
            }
            else if (!curw.isOwned())
            {  // the object is currently not owned.
               // between opening it for read and validating, another
               // transaction opened it for update with or without successful
               // commitment.
               becomeInvalid();
            }
            else if (curw.getOwnerFromSTMWord() == this)
            {  // the object is currently owned by this transaction

               // now, we have to read the state of txo at the time
               // of opening it for update.
               var u:Node_Ulog = curw.getEntryFromSTMWord();

               // the state of txo right before being acquired is
               // compared with its state when it was read. 
               if (!u.getW().equals(olds.toWord()))
               {  // another transaction opened the object for update
                  // between the opening for read and this transaction's 
                  // open for update.
                  // if the object was opened for update by another transaction
                  // after having it opened for read, tried to commit, 
                  // regardless of the outcome of the commitment, then this
                  // transaction opened the object for update, the control 
                  // would be here. version number is necessarily different
                  // due to the interfering other transaction (note that,
                  // abort also changes the version number of its update
                  // objects).

                  // the read was invalid -> abort transaction.
                  becomeInvalid();
               }
               else
               {  // the stm-word read from the udpate-log entry and the
                  // original stm-word are the same. this means that there 
                  // was no interfering transaction between the read and 
                  // the open for update events. 
               }
            }
            else
            {  // the current owner is some other transaction.

               // the read was invalid -> abort transaction.
               becomeInvalid();
            }
         }
         else
         {  // txo was already owned by some transaction at the time 
            // of read.

            if (curw.getOwnerFromSTMWord() == this)
            {  // object was already owned by this transaction at the
               // time of opening it for read. so, validate. <- wrong.
               /***********************************************************/
               /* !!!!!!!!!!!!!!! bug bug bug !!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
               /* if the object was owned by another transaction at 
                * the time of opening for read, that transaction committed 
                * or aborted which was followed by this transaction opening
                * the object for update in which case the current owner would
                * be this transaction, the above check would evaluate to
                * true and incorrectly we would validate the read. 
                * the real check should be made for oldw; that is, the
                * owner at the time of opening for read should be controlled.
                */
               /***********************************************************/
               if ((!BUGGY) && (oldw.getOwnerFromSTMWord() != this))
               {  // the owner of txo was not this transaction at the time
                  // of this read.

                  // the read was invalid -> abort transaction.
                  becomeInvalid();
               }
            }
            else
            {  // object was already owned by another transaction
               // at the time of opening it for read.
               // if control is here, it means that the current owner of the
               // object whose read is being checked is another transaction.
               // even though txo was owned at the time of read 
               // by some transaction i, and is currently owned by some
               // transaction j, and i,j != this transaction, i and j are
               // not necessarily the same transaction.

               /* note that, despite what the comment in the pseudo-code of 
                * the pldi06 paper says, if control is here, the stm-word
                * at the time of opening for read, old_stm_word, and the
                * stm-word read at the beginning of this method, cur_stm_word,
                * are not necessarily the same. 
                */

               // the read was invalid -> abort transaction.
               becomeInvalid();
            }
         }
      }
   }

   /* this method is used to commit the deferred
    * updates. each node in the update-log points to an object
    * opened for update, not necessarilly updated, by this
    * transaction. the update-log node also holds the original
    * stm-word of the object. this stm-word's version number
    * is incremented by 1 in GetNextVersion (also, the owned bit is
    * reset and the pointers are set to null). finally, the object
    * changes its version number as well via CloseSTMWord.
    */
   public function closeUpdatedObject( n:Node_Ulog):Void
   {
      // get the old state from the update-log entry
      var w :STMWord= n.getW();

      // modify the stm-word so that the txo will become
      // unowned and have its version incremented by 1.
      w.getNextVersion();

      // update the stm-word of txo. the snapshot reference
      // of the txo does not change; the stm-word inside
      // the snapshot is also updated in-place (Copy is called).
      n.getTxo().closeSTMWord(w);
   }

   /* the method is called whenever a transaction tries
    * to commit. first, the reads of the transaction are
    * validated. if successful, the logs are restored 
    * appropriately. if validation fails, DTMAbort is
    * called and the top-level caller is signalled of
    * the transaction's failure.
    * note that, the read-log is implicitly cleared via
    * DTMIsValid: after each read's validation, its entry
    * is removed from read-log. the other two logs have to
    * be explicitly restored.
    */
   public function commit():Void
   {
      // get the log bounds for the current transaction.
      //Node_MetaXact m = watermark.Last.Value;

      // verify that the reads done by this transaction are valid.
      try
      {
         isValid();
         // the reads are validated.

         // read the update-log bound for this transaction.
         // Node_Ulog u = m.getUmark();

         // until the nesting transaction's entries are reached
         // while (ulog.Last.Value != u)
         while (!ulog.isEmpty())
         {
            // update the global state of the txo 
            // corresponding to the current update-log entry.
            closeUpdatedObject(ulog.last());

            // remove the entry from the update-log.
            ulog.remove(ulog.last());
         }

         // the undo-log is restored; just remove the
         // entries corresponding to this transaction.
         // ClearRollbackLog(m.getRbmark());
         clearRollbackLog();
      }
      catch ( e:AtomicIsInvalidException)
      {  // at least one of the reads was not valid.

         // abort the current transaction.
         // DTMAbort throws an exception upon completion.
         // propagate it to the user.
         abort();
      }
   }

   /* can be called explicitly or within DTMCommit as its first step.
    * it iterates over the read-log, tries to validate each entry.
    * if validation fails for at least one such entry, it returns false.
    * otherwise, it returns true. 
    */
   public function isValid():Void
   {
      // get the log bounds for the current transaction
      // Node_MetaXact m = watermark.Last.Value;

      // AtomicIsInvalidException might be thrown by BecomeInvalid
      // which will be called by ValidateReadObject.
      // get the bound for the read-log
      // Node_Rlog r = m.getRmark();

      // until the nesting transaction's entries are reached...
      // while (rlog.Last.Value != r)
      while (!rlog.isEmpty())
      {
         // try to validate the object corresponding to the
         // current read-log entry. 
         // throws AtomicIsInvalidException via BecomeInvalid; 
         // propagated to the caller.
         validateReadObject(rlog.last());

         // remove that entry, in case the read was valid.
         // if the read was not valid, control would not 
         // come here; the exception will be caught.
         rlog.remove(rlog.last());
      }
   }


   // the following is run-time relevant and ignored.
   public function start():Void 
   {
	   
	}

   // The following are not applicable for C# and ignored.	
   // public object addrToSurrogate(int a) { return null; }
   // public void logAddrStore(int a) { }
	
}