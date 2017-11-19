package com.er453r.hxtive;

import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Expr.FieldType;
import com.er453r.macros.MacroUtils;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr.Field;
import haxe.macro.Context;
import haxe.macro.Expr;

class Reactor {
	public static function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var className:String = TypeTools.toString(Context.getLocalType());

		trace("[" + className + "] ");

		for(field in fields.copy()){
			trace("[" + className + "] " + field.name);

			var inject:Bool = false;

			switch(field.kind){
				case FieldType.FProp(get, set, type, expr):{
					trace('property ${ComplexTypeTools.toString(type)}, ${field.name} ${ExprTools.toString(expr)}');

					inject = true;
				}
				case FieldType.FVar(type, expr):{
					trace('variable ${ComplexTypeTools.toString(type)}, ${field.name}  ${ExprTools.toString(expr)}');

					//trace(type);
//					trace(TypeTools.getClass(TypeTools.followWithAbstracts(ComplexTypeTools.toType(type))));

					trace(ComplexTypeTools.toType(type));

					inject = true;
				}

				default: {}
			}

			if(inject){
				// if has no setter
				if(MacroUtils.getField(MacroUtils.SETTER_PREFIX + field.name, fields) == null){
					trace('creating setter for ${field.name}!');

					// inject setter
					fields.push({
						name: MacroUtils.SETTER_PREFIX + field.name,
						kind: FieldType.FFun({
							args: [{ name:'value', type:null}],
							expr: macro return $i{field.name} = value,
							ret: null
						}),
						pos: Context.currentPos()
					});

					// enable setter
					switch(field.kind){
						case FVar(t, e):{
							field.kind = FieldType.FProp("null", "set", t, e);
						}

						// if only getter exists
						case FProp(get, set, t, e):{
							field.kind = FieldType.FProp(get, "set", t, e);

							if (field.meta == null)
								field.meta = [];

							field.meta.push({
								name: ":isVar",
								pos: field.pos,
								params: []
							});
						}

						default: {}
					}
				}

				// inject code to setter
				switch(MacroUtils.getField(MacroUtils.SETTER_PREFIX + field.name, fields).kind){
					case FFun(func):{
						trace("injecting setter!");

						var core:Bool = (field.name != "eee"); // TODO check actuall type

						if(core){
							func.expr = macro {
								trace('[${className}] "${field.name}" core update to: ' + Std.string($i{func.args[0].name}));

								${func.expr};
							};
						}
						else{
							func.expr = macro {
								trace('[${className}] "${field.name}" object update to: ' + Std.string($i{func.args[0].name}));

								//$i{func.args[0].name}.listeners.push(onUpdate);

								trace($i{func.args[0].name}.listeners);

								${func.expr};
							};
						}
					}

					default: {}
				}

				trace("[" + className + "] " + "setters done...");
			}
		}

		trace("[" + className + "] Injecting onUpdate");

		// inject update
		fields.push({
			name: "onUpdate",
			kind: FieldType.FFun({
				args: [],
				expr: macro {
					trace('[${className}] OBJECT UPDATE');
				},
				ret: null
			}),
			pos: Context.currentPos()
		});

		trace("[" + className + "] Injecting listeners");

		// inject listeners
		fields.push({
			name: "listeners",
			access: [Access.APublic],
			kind: FieldType.FVar(macro:Array<Void->Void>, macro $v{new Array<Void->Void>()}),
			pos: Context.currentPos()
		});

		trace("[" + className + "] " + "DONE");

		return fields;
	}
}
