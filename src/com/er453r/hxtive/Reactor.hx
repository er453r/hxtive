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

		trace('[${className}}] REACTING');

		for(field in fields.copy()){
			var inject:Bool = false;

			var complexType:ComplexType = null;

			switch(field.kind){
				case FieldType.FProp(get, set, type, expr):{
					trace('[${className}}] [${field.name}] property ${ComplexTypeTools.toString(type)}, ${field.name} ${ExprTools.toString(expr)}');

					complexType = type;

					inject = true;
				}
				case FieldType.FVar(type, expr):{
					trace('[${className}}] [${field.name}] variable ${ComplexTypeTools.toString(type)}, ${field.name} ${ExprTools.toString(expr)}');

					complexType = type;

					inject = true;
				}

				default: {}
			}

			if(inject){
				// if has no setter
				if(MacroUtils.getField(MacroUtils.SETTER_PREFIX + field.name, fields) == null){
					trace('[${className}}] [${field.name}] creating setter');

					// inject setter
					fields.push({
						name: MacroUtils.SETTER_PREFIX + field.name,
						kind: FieldType.FFun({
							args: [{ name:'value', type:complexType}],
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
						trace('[${className}}] [${field.name}] injecting setter');

						var core:Bool = (field.name != "eee"); // TODO check actuall type

						if(core){
							func.expr = macro {
								trace('[${className}] "${field.name}" core update to: ' + Std.string($i{func.args[0].name}));

								notify();

								${func.expr};
							};
						}
						else{
							func.expr = macro {
								trace('[${className}] "${field.name}" object update to: ' + Std.string($i{func.args[0].name}));

								$i{func.args[0].name}.listeners.push(onUpdate);

								notify();

								${func.expr};
							};
						}
					}

					default: {}
				}

				trace('[${className}}] [${field.name}] setter done');
			}
		}

		trace('[${className}}] injecting onUpdate');

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

		// inject update
		fields.push({
			name: "notify",
			kind: FieldType.FFun({
				args: [],
				expr: macro {
					trace('[${className}] OBJECT NOTIFY');

					for(listener in listeners)
						listener();
				},
				ret: null
			}),
			pos: Context.currentPos()
		});

		trace('[${className}}] injecting listeners');

		// inject listeners
		fields.push({
			name: "listeners",
			access: [Access.APublic],
			kind: FieldType.FVar(macro:Array<Void->Void>, macro $v{new Array<Void->Void>()}),
			pos: Context.currentPos()
		});

		trace('[${className}}] DONE');

		return fields;
	}
}
