package com.er453r.hxtive;

import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Expr.FieldType;
import com.er453r.macros.MacroUtils;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr.Field;
import haxe.macro.Context;

class Reactor {
	public static function build():Array<Field> {
		trace("macro build");

		var fields:Array<Field> = Context.getBuildFields();
		var className:String = TypeTools.toString(Context.getLocalType());

		for(field in fields){
			//trace("field" + field);

			var inject:Bool = false;

			switch(field.kind){
				case FieldType.FProp(get, set, type, expr):{
					trace('property ${ComplexTypeTools.toString(type)}, ${field.name} ${ExprTools.toString(expr)}');

					inject = true;
				}
				case FieldType.FVar(type, expr):{
					trace('variable ${ComplexTypeTools.toString(type)}, ${field.name}  ${ExprTools.toString(expr)}');

					inject = true;
				}

				default: {}
			}

			if(inject){
				// if has no setter
				if(MacroUtils.getField(MacroUtils.SETTER_PREFIX + field.name, fields) == null){
					trace("creating setter!");

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

						func.expr = macro {
							trace('[${className}] "${field.name}" update to: ' + Std.string($i{func.args[0].name}));
							onUpdate();
							${func.expr};
						};
					}

					default: {}
				}
			}
		}



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

		return fields;
	}
}
