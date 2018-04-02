package com.er453r.hxtive;

class ChangeEvent {
	public var subject:Any;
	public var fieldName:String;
	public var oldValue:Any;
	public var newValue:Any;
	public var parent:ChangeEvent;

	public function new(?subject:Any, ?fieldName:String, ?oldValue:Any, ?newValue:Any, ?parent:ChangeEvent) {
		this.subject = subject;
		this.fieldName = fieldName;
		this.oldValue = oldValue;
		this.newValue = newValue;
		this.parent = parent;
	}
}
