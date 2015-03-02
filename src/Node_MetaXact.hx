package ;

/**
 * ...
 * @author 
 */
class Node_MetaXact
{
/* this class is used to handle nested transactions.
 * each transaction has its own set of logs:
 * the read-log, the undo-log and the update-log. 
 * each node has three pointers, one per log and they
 * each point to the last node prior to the beginning
 * of the innermost transaction currently active.
 */
  private  var rmark :Node_Rlog ;
  private var umark: Node_Ulog ;
  private var  rbmark:Node_RBlog ;

  public function new( rmark:Node_Rlog,  umark:Node_Ulog,  rbmark:Node_RBlog)
  {
    this.rmark = rmark;
    this.umark = umark;
    this.rbmark = rbmark;
  }

  public function getRmark():Node_Rlog { return rmark; }
  public function getUmark():Node_Ulog { return umark; }
  public function getRbmark():Node_RBlog { return rbmark; }
	 
	
}