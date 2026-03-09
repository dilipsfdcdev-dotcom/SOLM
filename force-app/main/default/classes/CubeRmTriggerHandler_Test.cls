@isTest
private class CubeRmTriggerHandler_Test {
    
    private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';
    private static final String TRIGGER_EXCEPTION_STATEMENT = 'the exception thrown was not expected: ';
    private static final String TRIGGER_BYPASS = 'test handler should be bypassed';
    
    private static String lastMethodCalled;
    
    private static CubeRmTriggerHandler_Test.TestHandler handler;
    
    static {
        handler = new CubeRmTriggerHandler_Test.TestHandler();
        // override its internal trigger detection
        handler.isTriggerExecuting = true;
    }
    
    /***************************************
* unit tests
***************************************/
    
    // contexts tests
    
    @isTest
    static void testBeforeInsert() {
        beforeInsertMode();
        handler.run();
        System.assertEquals('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
    }
    
    @isTest
    static void testBeforeUpdate() {
        beforeUpdateMode();
        handler.run();
        System.assertEquals('beforeUpdate', lastMethodCalled, 'last method should be beforeUpdate');
    }
    
    @isTest
    static void testBeforeDelete() {
        beforeDeleteMode();
        handler.run();
        System.assertEquals('beforeDelete', lastMethodCalled, 'last method should be beforeDelete');
    }
    
    @isTest
    static void testAfterInsert() {
        afterInsertMode();
        handler.run();
        System.assertEquals('afterInsert', lastMethodCalled, 'last method should be afterInsert');
    }
    
    @isTest
    static void testAfterUpdate() {
        afterUpdateMode();
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method should be afterUpdate');
    }
    
    @isTest
    static void testAfterDelete() {
        afterDeleteMode();
        handler.run();
        System.assertEquals('afterDelete', lastMethodCalled, 'last method should be afterDelete');
    }
    
    @isTest
    static void testAfterUndelete() {
        afterUndeleteMode();
        handler.run();
        System.assertEquals('afterUndelete', lastMethodCalled, 'last method should be afterUndelete');
    }
    
    @isTest 
    static void testNonTriggerContext() {
        try{
            handler.run();
            System.assert(false, 'the handler ran but should have thrown');
        } catch(CubeRmTriggerHandler.CubeRmTriggerHandlerException te) {
            System.assertEquals(TRIGGER_CONTEXT_ERROR, te.getMessage(), 'the exception message should match');
        } catch(Exception e) {
            System.assert(false, TRIGGER_EXCEPTION_STATEMENT + e.getTypeName() + ': ' + e.getMessage());
        }
    }
    
    // test bypass api
    
    @isTest
    static void testBypassAPI() {
        afterUpdateMode();
        
        // test a bypass and run handler
        CubeRmTriggerHandler.bypass('TestHandler');
        handler.run();
        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, CubeRmTriggerHandler.isBypassed('TestHandler'), TRIGGER_BYPASS);
        resetTest();
        
        // clear that bypass and run handler
        CubeRmTriggerHandler.clearBypass('TestHandler');
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, CubeRmTriggerHandler.isBypassed('TestHandler'), TRIGGER_BYPASS);
        resetTest();
        
        // test a re-bypass and run handler
        CubeRmTriggerHandler.bypass('TestHandler');
        handler.run();
        System.assertEquals(null, lastMethodCalled, 'last method should be null when bypassed');
        System.assertEquals(true, CubeRmTriggerHandler.isBypassed('TestHandler'), TRIGGER_BYPASS);
        resetTest();
        
        // clear all bypasses and run handler
        CubeRmTriggerHandler.clearAllBypasses();
        handler.run();
        System.assertEquals('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        System.assertEquals(false, CubeRmTriggerHandler.isBypassed('TestHandler'), TRIGGER_BYPASS);
        resetTest();
    }
    
    // instance method tests
    
    @isTest
    static void testLoopCount() {
        beforeInsertMode();
        
        // set the max loops to 2
        handler.setMaxLoopCount(2);
        
        // run the handler twice
        handler.run();
        handler.run();
        
        // clear the tests
        resetTest();
        
        try {
            // try running it. This should exceed the limit.
            handler.run();
            System.assert(false, 'the handler should throw on the 3rd run when maxloopcount is 3');
        } catch(CubeRmTriggerHandler.CubeRmTriggerHandlerException te) {
            // we're expecting to get here
            System.assertEquals(null, lastMethodCalled, 'last method should be null');
        } catch(Exception e) {  
            System.assert(false, TRIGGER_EXCEPTION_STATEMENT + e.getTypeName() + ': ' + e.getMessage());
        }
        
        // clear the tests
        resetTest();
        
        // now clear the loop count
        handler.clearMaxLoopCount();
        
        try {
            // re-run the handler. We shouldn't throw now.
            handler.run();
            System.assertEquals('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
        } catch(CubeRmTriggerHandler.CubeRmTriggerHandlerException te) {
            System.assert(false, 'running the handler after clearing the loop count should not throw');
        } catch(Exception e) {  
            System.assert(false, TRIGGER_EXCEPTION_STATEMENT + e.getTypeName() + ': ' + e.getMessage());
        }
    }
    
    @isTest
    static void testLoopCountClass() {
        CubeRmTriggerHandler.LoopCount lc = new CubeRmTriggerHandler.LoopCount();
        System.assertEquals(5, lc.getMax(), 'max should be five on init');
        System.assertEquals(0, lc.getCount(), 'count should be zero on init');
        
        lc.increment();
        System.assertEquals(1, lc.getCount(), 'count should be 1');
        System.assertEquals(false, lc.exceeded(), 'should not be exceeded with count of 1');
        
        lc.increment();
        lc.increment();
        lc.increment();
        lc.increment();
        System.assertEquals(5, lc.getCount(), 'count should be 5');
        System.assertEquals(false, lc.exceeded(), 'should not be exceeded with count of 5');
        
        lc.increment();
        System.assertEquals(6, lc.getCount(), 'count should be 6');
        System.assertEquals(true, lc.exceeded(), 'should not be exceeded with count of 6');
    }
    
    // private method tests
    
    @isTest 
    static void testGetHandlerName() {
        System.assertEquals('TestHandler', handler.getHandlerName(), 'handler name should match class name');
    }
    
    // test virtual methods
    
    @isTest
    static void testVirtualMethods() {
        CubeRmTriggerHandler h = new CubeRmTriggerHandler();
        h.beforeInsert();
        h.beforeUpdate();
        h.beforeDelete();
        h.afterInsert();
        h.afterUpdate();
        h.afterDelete();
        h.afterUndelete();
    }
    
    /***************************************
* testing utilities
***************************************/
    
    private static void resetTest() {
        lastMethodCalled = null;
    }
    
    // modes for testing
    
    private static void beforeInsertMode() {
        handler.setTriggerContext('before insert', true);
        try{
            CubeRmTenderLotProductTriggerHandler cls = new CubeRmTenderLotProductTriggerHandler();
            cls.beforeInsert();
        }catch(exception exp){
            system.debug('Exception exp : ' + exp.getMessage());
        }
    }
    
    private static void beforeUpdateMode() {
        
        handler.setTriggerContext('before update', true);
        
        try{
            CubeRmTenderLotProductTriggerHandler cls = new CubeRmTenderLotProductTriggerHandler();
            cls.beforeUpdate();
        }catch(exception exp){
            system.debug('Exception exp : ' + exp.getMessage());
        }
    }
    
    private static void beforeDeleteMode() {
        handler.setTriggerContext('before delete', true);
    }
    
    private static void afterInsertMode() {
        handler.setTriggerContext('after insert', true);
        try{
            CubeRmTenderLotProductTriggerHandler cls = new CubeRmTenderLotProductTriggerHandler();
            cls.afterInsert();
        }catch(exception exp){
            system.debug('Exception exp : ' + exp.getMessage());
        }
    }
    
    private static void afterUpdateMode() {
        handler.setTriggerContext('after update', true);
    }
    
    private static void afterDeleteMode() {
        handler.setTriggerContext('after delete', true);
    }
    
    private static void afterUndeleteMode() {
        handler.setTriggerContext('after undelete', true);
    }
    
    // test implementation of the CubeRmTriggerHandler
    
    private class TestHandler extends CubeRmTriggerHandler {
        
        public override void beforeInsert() {
            CubeRmTriggerHandler_Test.lastMethodCalled = 'beforeInsert';
        }
        
        public override void  beforeUpdate() {
            CubeRmTriggerHandler_Test.lastMethodCalled = 'beforeUpdate';
        }
        
        public override void beforeDelete() {
            CubeRmTriggerHandler_Test.lastMethodCalled = 'beforeDelete';
        }
        
        public override void afterInsert() {
            CubeRmTriggerHandler_Test.lastMethodCalled = 'afterInsert';
        }
        
        public override void afterUpdate() {
            CubeRmTriggerHandler_Test.lastMethodCalled = 'afterUpdate';
        }
        
        public override void afterDelete() {
            CubeRmTriggerHandler_Test.lastMethodCalled = 'afterDelete';
        }
        
        public override void afterUndelete() {
            CubeRmTriggerHandler_Test.lastMethodCalled = 'afterUndelete';
        }
        
    }
    
}