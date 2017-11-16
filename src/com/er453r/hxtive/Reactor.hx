package com.er453r.hxtive;

import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr.Field;
import haxe.macro.Context;

class Reactor {
	public static function build():Array<Field> {
		trace("macro build");

		var fields:Array<Field> = Context.getBuildFields();

		for(field in fields){
			trace("field" + field);

			switch(field.kind){
				case FVar(type, expr):{
					trace("variable");

					trace(ComplexTypeTools.toString(type));

					/*switch(type){
						case TPath(type):{
							trace("field" + type.name);
						}

						default: {}
					}*/
				}

				default: {}
			}
		}

		return fields;
	}
}
