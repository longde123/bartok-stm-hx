package ;

/**
 * ...
 * @author 
 */
class Random
{

	public function new() 
	{
		
	}
	  public function next(?r:Float=1):Float {
		   return randRange(0,r*100)/100;
	   }
	   
	  public function    nextDouble():Float {
		  return randRange(0,1*100)/100;
	  }
	  private function randRange(min:Float, max:Float):Float {
		  var n:Float = Math.floor(Math.random() * (max - min + 1)) + min;
		  return n;
	  }
}