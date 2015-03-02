package ;
import neko.vm.Mutex ;
import neko.vm.Deque ;



class   MyHeap <T>{
	
	private var mutex:Mutex;
	private var deque:Array<T>;
	public function new():Void {
		deque = new Array<T>();
		mutex = new Mutex();
	}
	
	public function add(o:T):Void {
		mutex.acquire();
		deque.push(o);
		mutex.release();
	}
	public function get(i:Int):T
	{
		var result:T;
	     mutex.acquire();
		 result = deque[i];
		 mutex.release();
		return result;
		 
	}
	public function size():Int {
		var len:Int;
	 	mutex.acquire();
		len= deque.length;
	    mutex.release();
		return len;
	}
}
 