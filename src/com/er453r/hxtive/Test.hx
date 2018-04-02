package com.er453r.hxtive;

import com.er453r.hxtive.test.TestObject;

class Test{
	public static function main(){
		trace("Start");

		var testObject:TestObject = new TestObject();

		testObject.name = "new name";

		trace("Done");
	}
}
