package starling.unit
{
    import flash.utils.getTimer;
    
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.utils.Color;
    import starling.utils.HAlign;
    import starling.utils.formatString;
    
    public class TestGui extends Sprite
    {
        private static const LINE_HEIGHT:int = 10;
        private static const FONT_NAME:String = "mini";
        private static const FONT_SIZE:int = -1;
        
        private var mTestRunner:TestRunner;
        private var mWidth:int;
        private var mHeight:int;
        private var mLoop:Boolean;
        private var mTestCount:int;
        private var mSuccessCount:int;
        private var mLogLines:Sprite;
        private var mNumLogLines:int;
        private var mStatusInfo:TextField;
        private var mStartMoment:Number;
        
        public function TestGui(testRunner:TestRunner, width:int, height:int)
        {
            mTestRunner = testRunner;
            mTestRunner.logFunction    = log;
            mTestRunner.assertFunction = assert;
            
            mWidth = width;
            mHeight = height;
            
            mStatusInfo = new TextField(width, LINE_HEIGHT, "", FONT_NAME, FONT_SIZE, Color.WHITE);
            mStatusInfo.hAlign = HAlign.RIGHT;
            addChild(mStatusInfo);
            
            mLogLines = new Sprite();
            addChild(mLogLines);
        }
        
        public function start(loop:Boolean=false):void
        {
            mLoop = loop;
            mStartMoment = getTimer() / 1000;
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        public function stop():void
        {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            mTestRunner.resetRun();
        }
        
        private function onEnterFrame(event:Event):void
        {
            var status:String = mTestRunner.runNext();
            
            if (status == TestRunner.STATUS_FINISHED)
            {
                var duration:int = getTimer() / 1000 - mStartMoment;
                stop();
                
                log("Finished all tests!", Color.AQUA);
                log("Duration: " + duration + " seconds.", Color.AQUA);
                
                if (mLoop) start(true);
            }
        }
        
        public function log(message:String, color:uint=0xffffff):void
        {
            trace(message);
            
            var logLine:TextField = new TextField(mWidth, LINE_HEIGHT, message, 
                                                  FONT_NAME, FONT_SIZE, color);
            logLine.hAlign = HAlign.LEFT;
            logLine.y = mNumLogLines * LINE_HEIGHT;
            mLogLines.addChild(logLine);
            mNumLogLines++;
            
            if (mNumLogLines * LINE_HEIGHT > mHeight)
            {
                mLogLines.removeChildAt(0);
                mLogLines.y -= LINE_HEIGHT;
            }
        }
        
        public function assert(success:Boolean, message:String=null):void
        {
            mTestCount++;
            
            if (success)
            {
                mSuccessCount++;
            }
            else
            {
                message = message ? message : "Assertion failed.";
                log(" " + message, Color.RED);
            }
            
            mStatusInfo.text = formatString("Passed {0} of {1} tests", mSuccessCount, mTestCount);
            mStatusInfo.color = (mSuccessCount == mTestCount) ? Color.GREEN : Color.RED;
        }
    }
}