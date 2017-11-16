package com.er453r.hxtive;

class Test{
	private var number:Float = 0.4;
	private var name:String = "BLorp";

	private var eee:Pff;

	public static function main(){
		new Test();
	}

	public function new (){
		trace("derp");

		trace('${number} ${name}');

		number = 4.5;
		name = "test";

		trace('${number} ${name}');

		eee = new Pff("lolz");

		eee.a = "pliz";
	}
}
