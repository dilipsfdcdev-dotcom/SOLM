public virtual class CubeRmTriggerHandler {

  // static map of handlername, times run() was invoked
  private static Map<String, LoopCount> loopCountMap;
  private static Set<String> bypassedHandlers;

  // the current context of the trigger, overridable in tests
  @TestVisible
  private TriggerContext context;

  // the current context of the trigger, overridable in tests
  @TestVisible
  private Boolean isTriggerExecuting;

  // static initialization
  static {
    loopCountMap = new Map<String, LoopCount>();
    bypassedHandlers = new Set<String>();
  }
  
  // constructor
  public CubeRmTriggerHandler() {
    this.setTriggerContext();
  }

  /***************************************
   * public instance methods
   ***************************************/

  // main method that will be called during execution
  public void run() {

    if(!validateRun()) {
      return;
    }

    addToLoopCount();

    // dispatch to the correct handler method
    switch on this.context {
      when BEFORE_INSERT {
        this.beforeInsert();
      }
      when BEFORE_UPDATE {
        this.beforeUpdate();
      }
      when BEFORE_DELETE {
        this.beforeDelete();
      }
      when AFTER_INSERT {
        this.afterInsert();
      }
      when AFTER_UPDATE {
        this.afterUpdate();
      }
      when AFTER_DELETE {
        this.afterDelete();
      }
      when AFTER_UNDELETE {
        this.afterUndelete();
      }
    }
  }

  public void setMaxLoopCount(Integer max) {
    String handlerName = getHandlerName();
    if(!CubeRmTriggerHandler.loopCountMap.containsKey(handlerName)) {
      CubeRmTriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
    } else {
      CubeRmTriggerHandler.loopCountMap.get(handlerName).setMax(max);
    }
  }

  public void clearMaxLoopCount() {
    this.setMaxLoopCount(-1);
  }

  /***************************************
   * public static methods
   ***************************************/

  public static void bypass(String handlerName) {
    CubeRmTriggerHandler.bypassedHandlers.add(handlerName);
  }

  public static void clearBypass(String handlerName) {
    CubeRmTriggerHandler.bypassedHandlers.remove(handlerName);
  }

  public static Boolean isBypassed(String handlerName) {
    return CubeRmTriggerHandler.bypassedHandlers.contains(handlerName);
  }

  public static void clearAllBypasses() {
    CubeRmTriggerHandler.bypassedHandlers.clear();
  }

  /***************************************
   * private instancemethods
   ***************************************/

  @TestVisible
  private void setTriggerContext() {
    this.setTriggerContext(null, false);
  }

  @TestVisible
  private void setTriggerContext(String ctx, Boolean testMode) {
    if(!Trigger.isExecuting && !testMode) {
      this.isTriggerExecuting = false;
      return;
    } else {
      this.isTriggerExecuting = true;
    }
    
    if(checkBeforeInsertContext(ctx)) {
      this.context = TriggerContext.BEFORE_INSERT;
    } else if(checkBeforeUpdateContext(ctx)){
      this.context = TriggerContext.BEFORE_UPDATE;
    } else if(checkBeforeDeleteContext(ctx)) {
      this.context = TriggerContext.BEFORE_DELETE;
    } else if(checkAfterInsertContext(ctx)) {
      this.context = TriggerContext.AFTER_INSERT;
    } else if(checkAfterUpdateContext(ctx)) {
      this.context = TriggerContext.AFTER_UPDATE;
    } else if(checkAfterDeleteContext(ctx)) {
      this.context = TriggerContext.AFTER_DELETE;
    } else if(checkAfterUndeleteContext(ctx)) {
      this.context = TriggerContext.AFTER_UNDELETE;
    }
  }
    
  public Boolean checkBeforeInsertContext(String ctx){
      return ((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) || (ctx != null && ctx == 'before insert'));
  }
    
  public Boolean checkBeforeUpdateContext(String ctx){
      return ((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) || (ctx != null && ctx == 'before update'));
  }
    
  public Boolean checkBeforeDeleteContext(String ctx){
      return ((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) || (ctx != null && ctx == 'before delete'));
  }
    
  public Boolean checkAfterInsertContext(String ctx){
      return ((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) || (ctx != null && ctx == 'after insert'));
  }
    
  public Boolean checkAfterUpdateContext(String ctx){
      return ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) || (ctx != null && ctx == 'after update'));
  }
    
  public Boolean checkAfterDeleteContext(String ctx){
      return ((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) || (ctx != null && ctx == 'after delete'));
  }
    
  public Boolean checkAfterUndeleteContext(String ctx){
      return ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) || (ctx != null && ctx == 'after undelete'));
  }

  // increment the loop count
  @TestVisible
  private void addToLoopCount() {
    String handlerName = getHandlerName();
    if(CubeRmTriggerHandler.loopCountMap.containsKey(handlerName)) {
      Boolean exceeded = CubeRmTriggerHandler.loopCountMap.get(handlerName).increment();
      if(exceeded) {
        Integer max = CubeRmTriggerHandler.loopCountMap.get(handlerName).max;
        throw new CubeRmTriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
      }
    }
  }

  // make sure this trigger should continue to run
  @TestVisible
  private Boolean validateRun() {
    if(!this.isTriggerExecuting || this.context == null) {
      throw new CubeRmTriggerHandlerException('Trigger handler called outside of Trigger execution');
    }
    return !CubeRmTriggerHandler.bypassedHandlers.contains(getHandlerName());
  }

  @TestVisible
  private String getHandlerName() {
    return this.toString().substringBefore(':');
  }

  /***************************************
   * context methods
   ***************************************/

  // context-specific methods for override
  @TestVisible
  protected virtual void beforeInsert(){}
  @TestVisible
  protected virtual void beforeUpdate(){}
  @TestVisible
  protected virtual void beforeDelete(){}
  @TestVisible
  protected virtual void afterInsert(){}
  @TestVisible
  protected virtual void afterUpdate(){}
  @TestVisible
  protected virtual void afterDelete(){}
  @TestVisible
  protected virtual void afterUndelete(){}

  /***************************************
   * inner classes
   ***************************************/

  // inner class for managing the loop count per handler
  @TestVisible
  private class LoopCount {
    private Integer max;
    private Integer count;

    public LoopCount() {
      this.max = 5;
      this.count = 0;
    }

    public LoopCount(Integer max) {
      this.max = max;
      this.count = 0;
    }

    public Boolean increment() {
      this.count++;
      return this.exceeded();
    }

    public Boolean exceeded() {
      return this.max >= 0 && this.count > this.max;
    }

    public Integer getMax() {
      return this.max;
    }

    public Integer getCount() {
      return this.count;
    }

    public void setMax(Integer max) {
      this.max = max;
    }
  }

  // possible trigger contexts
  @TestVisible
  private enum TriggerContext {
    BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
    AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
    AFTER_UNDELETE
  }

  // exception class
  public class CubeRmTriggerHandlerException extends Exception {}

}