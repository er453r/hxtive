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
							args: [{ name:'derp', type:complexType}],
							expr: macro return $i{field.name} = derp, // this does not work with 'value' name
							ret: complexType
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

								//notify(field.name, func.args[0].name, func.args[0].name, null);

								${func.expr};
							};
						}
						else{
							func.expr = macro {
								trace('[${className}] "${field.name}" object update to: ' + Std.string($i{func.args[0].name}));

								$i{func.args[0].name}.listeners.push(onUpdate);

								//notify();

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
/*		fields.push({
			name: "notify",
			kind: FieldType.FFun({
				args: [{ name:'field', type:String}, { name:'oldValue', type:Any}, { name:'newValue', type:Any}, { name:'parent', type:ChangeEvent}],
				expr: macro {
					var event:ChangeEvent = new ChangeEvent(this, field, oldValue, newValue, parent);

					for(listener in listeners)
						listener(event);
				},
				ret: null
			}),
			pos: Context.currentPos()
		});*/

		var stringType:ComplexType = Context.toComplexType(Context.getType("String"));
		var anyType:ComplexType = Context.toComplexType(Context.getType("Any"));
		var changeEventType:ComplexType = Context.toComplexType(Context.getType("ChangeEvent"));

		fields.push({
			name: "notify",
			kind: FieldType.FFun({
				args: [{ name:'fieldName', type:stringType}, {name:'oldValue', type:anyType}, {name:'newValue', type:anyType}, {name:'parent', type:changeEventType}],
				expr: macro {
					var event:ChangeEvent = new ChangeEvent(null, fieldName, oldValue, newValue, parent);

					for(listener in listeners)
						listener(event);
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
			kind: FieldType.FVar(macro:Array<ChangeEvent->Void>, macro $v{new Array<ChangeEvent->Void>()}),
			pos: Context.currentPos()
		});

		trace('[${className}}] DONE');

		return fields;
	}
}
