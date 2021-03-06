/*
Copyright 2017 Bowler Hat LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package
{
	public class FlexJSGenerator extends yeomanGenerator
	{
		private static const CONFIG_ASCONFIG:String = "asconfig.json";
		private static const CONFIG_XML:String = "App-config.xml";
		private static const CONFIG_MANUAL:String = "No configuration file";

		private static const TARGET_JS_FLEX:String = "JSFlex";
		private static const TARGET_SWF:String = "SWF";

		public function FlexJSGenerator(args:Object, options:Object)
		{
			super(args, options);
			this.log(yosay(
				"Let's create an\n" + chalk.green("Apache FlexJS") + "\napplication with the\n" + chalk.cyan("Express") + " component set."
			));
		}

		private var _configResult:String;
		private var _targetsResult:Array;
		private var _applicationNameResult:String;
		private var _initialViewNameResult:String;
		private var _configXML:Object = {name: CONFIG_XML, value: CONFIG_XML};

		public function prompting():Object
		{
			return this.prompt(
			[
				{
					"name": "name",
					"message": "What is the name of your project's main class?",
					"type": "input",
					"default": this.appname.replace(/[^\w$]/g, ""),
					"validate": _private_validateName
				},
				{
					"name": "initialViewName",
					"message": "What is the name of your application's initial view?",
					"type": "input",
					"default": "InitialView"
				},
				{
					"name": "config",
					"message": "Would you like to store configuration options in a file?",
					"type": "list",
					"choices": [CONFIG_MANUAL, CONFIG_ASCONFIG, this._configXML]
				},
				{
					"name": "targets",
					"type": "checkbox",
					"message": "Which output targets should be generated?",
					"choices": [TARGET_JS_FLEX, TARGET_SWF],
					"default": [TARGET_JS_FLEX],
					"when": _private_whenConfig
				}
			]).then(_private_onPromptsComplete);
		}

		public function copyApplication():void
		{
			var splitClassName:Array = this._initialViewNameResult.split(".");
			var pathWithPackage:String = splitClassName.join("/");
			var initialViewComponentName:String = splitClassName.pop();
			var initialViewNamespace:String = "*";
			if(splitClassName.length > 0)
			{
				initialViewNamespace = splitClassName.join(".") + ".*";
			}
			var contents:String = this.fs.read(this.templatePath("App.mxml"));
			contents = contents.replace(/\$\{initialview.name\}/g, initialViewComponentName);
			contents = contents.replace(/\$\{initialview.namespace\}/g, initialViewNamespace);
			this.fs.write(this.destinationPath("src/" + this._applicationNameResult + ".mxml"), contents);
			this.fs.copy(this.templatePath("InitialView.mxml"), this.destinationPath("src/" + pathWithPackage + ".mxml"));
		}

		public function copyConfig():void
		{
			if(this._configResult === CONFIG_MANUAL)
			{
				return;
			}
			switch(this._configResult)
			{
				case CONFIG_XML:
				{
					this._private_copyConfigXML();
					break;
				}
				case CONFIG_ASCONFIG:
				{
					this._private_copyASConfigJSON();
					break;
				}
			}
		}

		public function _private_validateName(input:String):Boolean
		{
			//the prompt for a later question should use the app name
			this._configXML.name = input + "-config.xml";
			return true;
		}

		public function _private_whenConfig(answers:Object):Object
		{
			return answers.config !== CONFIG_MANUAL;
		}

		public function _private_onPromptsComplete(answers:Object):void
		{
			this._applicationNameResult = answers.name as String;
			this._initialViewNameResult = answers.initialViewName as String;
			this._configResult = answers.config as String;
			this._targetsResult = answers.targets as Array;
		}

		public function _private_copyASConfigJSON():void
		{
			var asconfig:Object =
			{
				"compilerOptions":
				{
					"targets": this._targetsResult
				},
				"files":
				[
					"src/" + this._applicationNameResult + ".mxml"
				]
			};
			this.fs.writeJSON(this.destinationPath("asconfig.json"), asconfig);
		}

		public function _private_copyConfigXML():void
		{
			var contents:String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
				"<flex-config>\n" +
					"\t<compiler>\n" +
						"\t\t<targets>\n";
			var targetsCount:int = this._targetsResult.length;
			for(var i:int = 0; i < targetsCount; i++)
			{
				var target:String = this._targetsResult[i];
          		contents += "\t\t\t<target>" + target + "</target>\n";
			}
			contents += "\t\t</targets>\n" +
					"\t</compiler>\n" +
				"</flex-config>";
			this.fs.write(this.destinationPath("src/" + this._applicationNameResult + "-config.xml"), contents);
		}
	}
}