package com.er453r.hxtive.test;

class TestObject {
    public var name:String;
    public var value:Int;
    public var object:TestObject;

    public function new(?name:String, ?value:Int, ?object:TestObject) {
        this.name = name;
        this.value = value;
        this.object = object;
    }
}
