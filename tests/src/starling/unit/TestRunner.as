package starling.unit
{
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;
    
    import starling.utils.Color;
    import starling.utils.formatString;
    
    public class TestRunner
    {
        public static const STATUS_FINISHED:String = "finished";
        public static const STATUS_RUNNING:String  = "running";
        public static const STATUS_WAITING:String  = "waiting";
        
        private var mTests:Array;
        private var mLogFunction:Function;
        private var mAssertFunction:Function;
        private var mCurrentTestIndex:int;
        private var mWaiting:Boolean;
        
        public function TestRunner()
        {
            mTests = [];
            mCurrentTestIndex = 0;
            mWaiting = false;

            mLogFunction = trace;
            mAssertFunction = function(success:Boolean, message:String=null):void
            {
                if (success) trace("Success!");
                else trace(message ? "Assertion failed: " + message : "Assertion failed.");
            };
        }
        
        public function add(testClass:Class):void
        {
            var typeInfo:XML = describeType(testClass);
            
            for each (var method:XML in typeInfo.factory.method)
                if (method.@name.toLowerCase().indexOf("test") == 0)
                    mTests.push([testClass, method.@name.toString()]);
        }
        
        public function runNext():String
        {
            if (mWaiting) return STATUS_WAITING;
            if (mCurrentTestIndex == mTests.length) return STATUS_FINISHED;
            
            mWaiting = true;
            var testData:Array = mTests[mCurrentTestIndex++];
            runTest(testData[0], testData[1], onComplete);
            return mWaiting ? STATUS_WAITING : STATUS_RUNNING;
            
            function onComplete():void
            {
                mWaiting = false;
            }
        }
        
        public function resetRun():void
        {
            mCurrentTestIndex = 0;
        }

        private function runTest(testClass:Class, method:String, onComplete:Function):void
        {
            var className:String = getQualifiedClassName(testClass).split("::").pop();
            logFunction(formatString("{0}.{1} ...", className, method));
            
            var test:UnitTest = new testClass() as UnitTest;
            var async:Boolean = test[method].length != 0; 
            test.assertFunction = mAssertFunction;
            
            try
            {
                test.setUp();
                
                if (async) 
                {
                    test[method](tearDown);
                }
                else       
                {
                    test[method]();
                    tearDown();
                }
            }
            catch (e:Error)
            {
                mAssertFunction(false, "Error: " + e.message);
            }
            
            function tearDown():void
            {
                try { test.tearDown(); }
                catch (e:Error) { mAssertFunction(false, "Error: " + e.message); }
                
                onComplete();
            }
        }
        
        public function get assertFunction():Function { return mAssertFunction; }
        public function set assertFunction(value:Function):void { mAssertFunction = value; }
        
        public function get logFunction():Function { return mLogFunction; }
        public function set logFunction(value:Function):void { mLogFunction = value; }
   }
}